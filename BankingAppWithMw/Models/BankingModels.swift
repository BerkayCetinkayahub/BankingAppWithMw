//
//  BankingModels.swift
//  BankingAppWithMw
//
//  Created by Banking API Integration
//  Copyright © 2024 BankingAppWithMw. All rights reserved.
//

import Foundation

// MARK: - Account Models
struct AccountBalance: Codable {
    let accountId: Int
    let accountNumber: String
    let currency: Int
    let balance: Double
    let currencySymbol: String
    
    enum CodingKeys: String, CodingKey {
        case accountId = "AccountId"
        case accountNumber = "AccountNumber"
        case currency = "Currency"
        case balance = "Balance"
        case currencySymbol = "CurrencySymbol"
    }
}

struct AccountResponse: Codable {
    let success: Bool
    let data: [AccountBalance]?
    let message: String?
}

// MARK: - Transfer Models
struct TransferRequest: Codable {
    let fromAccountId: Int
    let toAccountId: Int
    let amount: Double
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case fromAccountId = "FromAccountId"
        case toAccountId = "ToAccountId"
        case amount = "Amount"
        case description = "Description"
    }
}

struct TransferResult: Codable {
    let success: Bool
    let message: String
    let transactionId: Int?
    let convertedAmount: Double?
    
    enum CodingKeys: String, CodingKey {
        case success = "Success"
        case message = "Message"
        case transactionId = "TransactionId"
        case convertedAmount = "ConvertedAmount"
    }
}

struct TransferResponse: Codable {
    let success: Bool
    let data: TransferResult?
    let message: String?
}

// MARK: - Exchange Rate Models
struct ExchangeRate: Codable {
    let fromCurrency: Int
    let toCurrency: Int
    let rate: Double
    let lastUpdated: String
    
    enum CodingKeys: String, CodingKey {
        case fromCurrency = "FromCurrency"
        case toCurrency = "ToCurrency"
        case rate = "Rate"
        case lastUpdated = "LastUpdated"
    }
}

struct ExchangeRateResponse: Codable {
    let success: Bool
    let data: [ExchangeRate]?
    let message: String?
}

// MARK: - Currency Types
enum CurrencyType: Int, CaseIterable {
    case try = 1
    case usd = 2
    case eur = 3
    
    var symbol: String {
        switch self {
        case .try:
            return "₺"
        case .usd:
            return "$"
        case .eur:
            return "€"
        }
    }
    
    var name: String {
        switch self {
        case .try:
            return "Türk Lirası"
        case .usd:
            return "Amerikan Doları"
        case .eur:
            return "Euro"
        }
    }
}
