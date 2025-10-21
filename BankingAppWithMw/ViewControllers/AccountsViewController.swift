//
//  AccountsViewController.swift
//  BankingAppWithMw
//
//  Created by Banking API Integration
//  Copyright © 2024 BankingAppWithMw. All rights reserved.
//

import UIKit

class AccountsViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var accountsTableView: UITableView!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    @IBOutlet weak var transferButton: UIBarButtonItem!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    private var accounts: [AccountBalance] = []
    private let apiService = BankingAPIService.shared
    private let userId = 1 // Test kullanıcısı
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadAccounts()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Hesaplarım"
        
        // TableView setup
        accountsTableView.delegate = self
        accountsTableView.dataSource = self
        accountsTableView.register(AccountTableViewCell.self, forCellReuseIdentifier: "AccountCell")
        
        // Loading indicator
        loadingIndicator.hidesWhenStopped = true
        
        // Navigation bar setup
        navigationItem.rightBarButtonItems = [transferButton, refreshButton]
    }
    
    // MARK: - Data Loading
    private func loadAccounts() {
        loadingIndicator.startAnimating()
        refreshButton.isEnabled = false
        
        apiService.fetchAccounts(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                self?.refreshButton.isEnabled = true
                
                switch result {
                case .success(let accounts):
                    self?.accounts = accounts
                    self?.accountsTableView.reloadData()
                case .failure(let error):
                    self?.showAlert(title: "Hata", message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Actions
    @IBAction func refreshButtonTapped(_ sender: UIBarButtonItem) {
        loadAccounts()
    }
    
    @IBAction func transferButtonTapped(_ sender: UIBarButtonItem) {
        showTransferViewController()
    }
    
    // MARK: - Navigation
    private func showTransferViewController() {
        guard let transferVC = storyboard?.instantiateViewController(withIdentifier: "TransferViewController") as? TransferViewController else {
            return
        }
        
        transferVC.accounts = accounts
        transferVC.onTransferCompleted = { [weak self] in
            self?.loadAccounts()
        }
        
        let navController = UINavigationController(rootViewController: transferVC)
        present(navController, animated: true)
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TableView DataSource
extension AccountsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccountCell", for: indexPath) as! AccountTableViewCell
        let account = accounts[indexPath.row]
        cell.configure(with: account)
        return cell
    }
}

// MARK: - TableView Delegate
extension AccountsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Custom TableView Cell
class AccountTableViewCell: UITableViewCell {
    
    private let accountNumberLabel = UILabel()
    private let balanceLabel = UILabel()
    private let currencyLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // Account number label
        accountNumberLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        accountNumberLabel.textColor = .label
        
        // Balance label
        balanceLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        balanceLabel.textColor = .systemBlue
        
        // Currency label
        currencyLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        currencyLabel.textColor = .secondaryLabel
        
        // Add to content view
        contentView.addSubview(accountNumberLabel)
        contentView.addSubview(balanceLabel)
        contentView.addSubview(currencyLabel)
        
        // Setup constraints
        accountNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        currencyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            accountNumberLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            accountNumberLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            accountNumberLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            balanceLabel.topAnchor.constraint(equalTo: accountNumberLabel.bottomAnchor, constant: 4),
            balanceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            currencyLabel.centerYAnchor.constraint(equalTo: balanceLabel.centerYAnchor),
            currencyLabel.leadingAnchor.constraint(equalTo: balanceLabel.trailingAnchor, constant: 8),
            currencyLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func configure(with account: AccountBalance) {
        accountNumberLabel.text = account.accountNumber
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        if let formattedBalance = formatter.string(from: NSNumber(value: account.balance)) {
            balanceLabel.text = formattedBalance
        } else {
            balanceLabel.text = "\(account.balance)"
        }
        
        currencyLabel.text = account.currencySymbol
    }
}
