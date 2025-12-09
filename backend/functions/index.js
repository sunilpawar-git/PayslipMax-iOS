const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { GoogleGenerativeAI } = require('@google/generative-ai');

// Initialize Firebase Admin
admin.initializeApp();

// Initialize Gemini AI (lazy initialization)
// Uses GEMINI_API_KEY environment variable (set via Firebase Secrets)
let genAI = null;

const getGenAI = () => {
    if (!genAI) {
        const apiKey = process.env.GEMINI_API_KEY;
        if (!apiKey) {
            throw new Error('GEMINI_API_KEY environment variable not set');
        }
        genAI = new GoogleGenerativeAI(apiKey);
    }
    return genAI;
};

/**
 * Cloud Function: parseLLM
 *
 * Proxies LLM requests from iOS app to Gemini API
 *
 * Features:
 * - Google Authentication required
 * - Rate limiting: 5 calls/hour, 50 calls/year
 * - Usage tracking in Firestore
 * - Comprehensive error handling
 *
 * Request: { prompt: string }
 * Response: { success: boolean, result: string, tokensUsed: number }
 */
exports.parseLLM = functions.https.onCall(async (data, context) => {
    const logger = functions.logger;

    try {
        // ============================================
        // 1. AUTHENTICATION
        // ============================================
        if (!context.auth) {
            logger.warn('Unauthenticated request attempt');
            throw new functions.https.HttpsError(
                'unauthenticated',
                'User must be authenticated with Google Sign-In'
            );
        }

        const userId = context.auth.uid;
        const userEmail = context.auth.token.email;
        logger.info(`Request from user: ${userId} (${userEmail})`);

        // ============================================
        // 2. INPUT VALIDATION
        // ============================================
        if (!data.prompt || typeof data.prompt !== 'string') {
            throw new functions.https.HttpsError(
                'invalid-argument',
                'Prompt must be a non-empty string'
            );
        }

        if (data.prompt.length > 100000) {
            throw new functions.https.HttpsError(
                'invalid-argument',
                'Prompt exceeds maximum length of 100KB'
            );
        }

        // ============================================
        // 3. RATE LIMITING
        // ============================================
        const db = admin.firestore();
        const usageRef = db.collection('llm_usage').doc(userId);
        const usageDoc = await usageRef.get();

        const now = new Date();
        const currentMonth = now.getMonth();
        const currentYear = now.getFullYear();
        const currentHour = now.getHours();

        const usage = usageDoc.exists ? usageDoc.data() : {
            yearlyCount: 0,
            year: currentYear,
            hourlyCount: 0,
            lastHourTimestamp: now,
            monthlyCount: 0,
            month: currentMonth,
            totalCount: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        };

        // Reset yearly count if new year
        if (usage.year !== currentYear) {
            usage.yearlyCount = 0;
            usage.year = currentYear;
        }

        // Reset monthly count if new month
        if (usage.month !== currentMonth) {
            usage.monthlyCount = 0;
            usage.month = currentMonth;
        }

        // Reset hourly count if new hour
        const lastHour = usage.lastHourTimestamp?.toDate?.()?.getHours() || 0;
        if (currentHour !== lastHour) {
            usage.hourlyCount = 0;
            usage.lastHourTimestamp = now;
        }

        // Check rate limits (PRODUCTION ONLY)
        // In development/emulator, skip rate limiting
        if (!process.env.FUNCTIONS_EMULATOR) {
            if (usage.yearlyCount >= 50) {
                logger.warn(`Rate limit exceeded (yearly) for user: ${userId}`);
                throw new functions.https.HttpsError(
                    'resource-exhausted',
                    'Yearly limit of 50 LLM calls reached. Limit resets on January 1st.'
                );
            }

            if (usage.hourlyCount >= 5) {
                logger.warn(`Rate limit exceeded (hourly) for user: ${userId}`);
                throw new functions.https.HttpsError(
                    'resource-exhausted',
                    'Hourly limit of 5 LLM calls reached. Please try again in an hour.'
                );
            }
        }

        // ============================================
        // 4. CALL GEMINI API
        // ============================================
        logger.info('Calling Gemini API...');

        const model = getGenAI().getGenerativeModel({
            model: 'gemini-2.0-flash-exp',
            generationConfig: {
                temperature: 0.0,
                maxOutputTokens: 1000,
            }
        });

        const result = await model.generateContent(data.prompt);
        const response = result.response;
        const text = response.text();
        const tokensUsed = response.usageMetadata?.totalTokenCount || 0;

        logger.info(`Gemini API success. Tokens used: ${tokensUsed}`);

        // ============================================
        // 5. UPDATE USAGE TRACKING
        // ============================================
        await usageRef.set({
            yearlyCount: usage.yearlyCount + 1,
            year: currentYear,
            hourlyCount: usage.hourlyCount + 1,
            lastHourTimestamp: now,
            monthlyCount: usage.monthlyCount + 1,
            month: currentMonth,
            totalCount: (usage.totalCount || 0) + 1,
            lastUsed: admin.firestore.FieldValue.serverTimestamp(),
            lastTokensUsed: tokensUsed,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        // ============================================
        // 6. RETURN RESPONSE
        // ============================================
        return {
            success: true,
            result: text,
            tokensUsed: tokensUsed,
            remainingCalls: {
                hourly: Math.max(0, 5 - (usage.hourlyCount + 1)),
                yearly: Math.max(0, 50 - (usage.yearlyCount + 1))
            }
        };

    } catch (error) {
        // Log error details
        logger.error('Error in parseLLM function:', error);

        // Re-throw HttpsError as-is
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }

        // Wrap other errors
        throw new functions.https.HttpsError(
            'internal',
            'An error occurred while processing your request',
            error.message
        );
    }
});

/**
 * Cloud Function: getUserUsage
 *
 * Returns current usage statistics for authenticated user
 */
exports.getUserUsage = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = context.auth.uid;
    const db = admin.firestore();
    const usageDoc = await db.collection('llm_usage').doc(userId).get();

    if (!usageDoc.exists) {
        return {
            yearlyCount: 0,
            hourlyCount: 0,
            monthlyCount: 0,
            totalCount: 0,
            limits: {
                hourly: 5,
                yearly: 50
            }
        };
    }

    const usage = usageDoc.data();
    return {
        yearlyCount: usage.yearlyCount || 0,
        hourlyCount: usage.hourlyCount || 0,
        monthlyCount: usage.monthlyCount || 0,
        totalCount: usage.totalCount || 0,
        lastUsed: usage.lastUsed,
        limits: {
            hourly: 5,
            yearly: 50
        },
        remaining: {
            hourly: Math.max(0, 5 - (usage.hourlyCount || 0)),
            yearly: Math.max(0, 50 - (usage.yearlyCount || 0))
        }
    };
});
