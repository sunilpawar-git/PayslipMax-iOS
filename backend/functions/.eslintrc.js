module.exports = {
    env: {
        es6: true,
        node: true,
    },
    parserOptions: {
        ecmaVersion: 2023,
    },
    extends: [
        'eslint:recommended',
        'google',
        'prettier',
    ],
    rules: {
        'no-restricted-globals': ['error', 'name', 'length'],
        'prefer-arrow-callback': 'error',
        'quotes': ['error', 'single', { 'allowTemplateLiterals': true }],
        'max-len': ['error', { 'code': 120 }],
        'no-unused-vars': ['error', { 'args': 'after-used', 'argsIgnorePattern': '^_' }],
        'eqeqeq': ['error', 'always'],
        'no-return-await': 'error',
    },
    overrides: [
        {
            files: ['**/*.spec.*'],
            env: {
                mocha: true,
            },
            rules: {},
        },
    ],
    globals: {},
};
