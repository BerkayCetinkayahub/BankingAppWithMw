//
//  BankingAPIService.swift
//  BankingAppWithMw
//
//  Created by Banking API Integration
//  Copyright © 2024 BankingAppWithMw. All rights reserved.
//

import Foundation

// MARK: - API Error Types
enum APIError: Error {
    case invalidURL
    case noData
    case serverError(String)
    case decodingError
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Geçersiz URL"
        case .noData:
            return "Veri bulunamadı"
        case .serverError(let message):
            return message
        case .decodingError:
            return "Veri çözümleme hatası"
        }
    }
}

// MARK: - Banking API Service
class BankingAPIService {
    static let shared = BankingAPIService()
    
    // Development URL - Production'da değiştirilecek
    private let baseURL = "http://localhost:5000"
    
    private init() {}
    
    // MARK: - Account Management
    
    /// Kullanıcının hesaplarını getirir
    /// - Parameters:
    ///   - userId: Kullanıcı ID'si
    ///   - completion: Completion handler
    func fetchAccounts(userId: Int, completion: @escaping (Result<[AccountBalance], APIError>) -> Void) {
        let urlString = "\(baseURL)/Handlers/AccountHandler.ashx?userId=\(userId)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.serverError(error.localizedDescription)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(AccountResponse.self, from: data)
                    if response.success, let accounts = response.data {
                        completion(.success(accounts))
                    } else {
                        completion(.failure(.serverError(response.message ?? "Bilinmeyen hata")))
                    }
                } catch {
                    completion(.failure(.decodingError))
                }
            }
        }.resume()
    }
    
    // MARK: - Money Transfer
    
    /// Hesaplar arası para transferi yapar
    /// - Parameters:
    ///   - request: Transfer isteği
    ///   - completion: Completion handler
    func transferMoney(request: TransferRequest, completion: @escaping (Result<TransferResult, APIError>) -> Void) {
        let urlString = "\(baseURL)/Handlers/TransferHandler.ashx"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
        } catch {
            completion(.failure(.decodingError))
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.serverError(error.localizedDescription)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(TransferResponse.self, from: data)
                    if response.success, let result = response.data {
                        completion(.success(result))
                    } else {
                        completion(.failure(.serverError(response.message ?? "Transfer başarısız")))
                    }
                } catch {
                    completion(.failure(.decodingError))
                }
            }
        }.resume()
    }
    
    // MARK: - Exchange Rates
    
    /// Güncel döviz kurlarını getirir
    /// - Parameter completion: Completion handler
    func fetchExchangeRates(completion: @escaping (Result<[ExchangeRate], APIError>) -> Void) {
        let urlString = "\(baseURL)/Handlers/ExchangeRateHandler.ashx"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.serverError(error.localizedDescription)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
                    if response.success, let rates = response.data {
                        completion(.success(rates))
                    } else {
                        completion(.failure(.serverError(response.message ?? "Döviz kurları alınamadı")))
                    }
                } catch {
                    completion(.failure(.decodingError))
                }
            }
        }.resume()
    }
}
