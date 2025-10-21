//
//  TransferViewController.swift
//  BankingAppWithMw
//
//  Created by Banking API Integration
//  Copyright © 2024 BankingAppWithMw. All rights reserved.
//

import UIKit

class TransferViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var fromAccountPicker: UIPickerView!
    @IBOutlet weak var toAccountPicker: UIPickerView!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var transferButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var exchangeRateLabel: UILabel!
    
    // MARK: - Properties
    var accounts: [AccountBalance] = []
    var onTransferCompleted: (() -> Void)?
    
    private let apiService = BankingAPIService.shared
    private var exchangeRates: [ExchangeRate] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadExchangeRates()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Para Transferi"
        
        // Navigation bar
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonTapped)
        )
        
        // Picker views
        fromAccountPicker.delegate = self
        fromAccountPicker.dataSource = self
        toAccountPicker.delegate = self
        toAccountPicker.dataSource = self
        
        // Text fields
        amountTextField.delegate = self
        amountTextField.keyboardType = .decimalPad
        amountTextField.placeholder = "Transfer tutarı"
        
        descriptionTextField.delegate = self
        descriptionTextField.placeholder = "Açıklama (opsiyonel)"
        
        // Button
        transferButton.layer.cornerRadius = 8
        transferButton.backgroundColor = .systemBlue
        transferButton.setTitleColor(.white, for: .normal)
        
        // Loading indicator
        loadingIndicator.hidesWhenStopped = true
        
        // Exchange rate label
        exchangeRateLabel.text = ""
        exchangeRateLabel.font = UIFont.systemFont(ofSize: 14)
        exchangeRateLabel.textColor = .secondaryLabel
        
        // Add toolbar to amount text field
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissKeyboard)
        )
        toolbar.setItems([doneButton], animated: false)
        amountTextField.inputAccessoryView = toolbar
    }
    
    // MARK: - Data Loading
    private func loadExchangeRates() {
        apiService.fetchExchangeRates { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let rates):
                    self?.exchangeRates = rates
                    self?.updateExchangeRateLabel()
                case .failure(let error):
                    print("Exchange rates error: \(error)")
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func transferButtonTapped(_ sender: UIButton) {
        performTransfer()
    }
    
    // MARK: - Transfer Logic
    private func performTransfer() {
        guard let amountText = amountTextField.text,
              let amount = Double(amountText),
              amount > 0 else {
            showAlert(title: "Hata", message: "Geçerli bir tutar giriniz")
            return
        }
        
        let fromAccountIndex = fromAccountPicker.selectedRow(inComponent: 0)
        let toAccountIndex = toAccountPicker.selectedRow(inComponent: 0)
        
        guard fromAccountIndex < accounts.count,
              toAccountIndex < accounts.count else {
            showAlert(title: "Hata", message: "Geçerli hesaplar seçiniz")
            return
        }
        
        let fromAccount = accounts[fromAccountIndex]
        let toAccount = accounts[toAccountIndex]
        
        guard fromAccount.accountId != toAccount.accountId else {
            showAlert(title: "Hata", message: "Aynı hesaba transfer yapılamaz")
            return
        }
        
        guard fromAccount.balance >= amount else {
            showAlert(title: "Hata", message: "Yetersiz bakiye")
            return
        }
        
        let transferRequest = TransferRequest(
            fromAccountId: fromAccount.accountId,
            toAccountId: toAccount.accountId,
            amount: amount,
            description: descriptionTextField.text?.isEmpty == false ? descriptionTextField.text : nil
        )
        
        loadingIndicator.startAnimating()
        transferButton.isEnabled = false
        
        apiService.transferMoney(request: transferRequest) { [weak self] result in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                self?.transferButton.isEnabled = true
                
                switch result {
                case .success(let result):
                    self?.showAlert(
                        title: "Başarılı",
                        message: result.message,
                        completion: {
                            self?.onTransferCompleted?()
                            self?.dismiss(animated: true)
                        }
                    )
                case .failure(let error):
                    self?.showAlert(title: "Hata", message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func updateExchangeRateLabel() {
        let fromAccountIndex = fromAccountPicker.selectedRow(inComponent: 0)
        let toAccountIndex = toAccountPicker.selectedRow(inComponent: 0)
        
        guard fromAccountIndex < accounts.count,
              toAccountIndex < accounts.count else {
            exchangeRateLabel.text = ""
            return
        }
        
        let fromAccount = accounts[fromAccountIndex]
        let toAccount = accounts[toAccountIndex]
        
        if fromAccount.currency == toAccount.currency {
            exchangeRateLabel.text = "Aynı para birimi - Çevrim gerekmez"
        } else {
            let rate = exchangeRates.first { rate in
                rate.fromCurrency == fromAccount.currency && rate.toCurrency == toAccount.currency
            }
            
            if let rate = rate {
                exchangeRateLabel.text = "1 \(fromAccount.currencySymbol) = \(String(format: "%.4f", rate.rate)) \(toAccount.currencySymbol)"
            } else {
                exchangeRateLabel.text = "Döviz kuru bulunamadı"
            }
        }
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}

// MARK: - PickerView DataSource
extension TransferViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return accounts.count
    }
}

// MARK: - PickerView Delegate
extension TransferViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard row < accounts.count else { return nil }
        let account = accounts[row]
        return "\(account.accountNumber) - \(account.balance) \(account.currencySymbol)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        updateExchangeRateLabel()
    }
}

// MARK: - TextField Delegate
extension TransferViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == descriptionTextField {
            dismissKeyboard()
        }
        return true
    }
}
