import Foundation
import SwiftUI
import SwiftData

// This file imports all necessary types for the network infrastructure
// and resolves circular dependencies

// Import PayslipItem from the Models directory
@objc protocol PayslipItemProtocol {}

// Forward declarations for types that might cause circular dependencies
typealias PayslipItem = Payslip_Max.PayslipItem

// Re-export the types from Network.swift
@_exported import struct Payslip_Max.PayslipBackup
@_exported import protocol Payslip_Max.NetworkServiceProtocol
@_exported import protocol Payslip_Max.CloudRepositoryProtocol
@_exported import protocol Payslip_Max.PayslipItemProtocol
@_exported import class Payslip_Max.PremiumFeatureManager
@_exported import enum Payslip_Max.NetworkError
@_exported import enum Payslip_Max.FeatureError
@_exported import class Payslip_Max.PlaceholderNetworkService
@_exported import class Payslip_Max.PlaceholderCloudRepository
@_exported import class Payslip_Max.MockNetworkService
@_exported import class Payslip_Max.MockCloudRepository 