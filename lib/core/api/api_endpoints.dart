class ApiEndpoints {
  // Default development local server URL
  // For Android Emulator use 10.0.2.2:8000, for iOS Simulator use localhost:8000, for physical device use LAN IP.
  static const String defaultBaseUrl = 'http://127.0.0.1:8000/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Dashboard & Transactions
  static const String dashboardSummary = '/dashboard/summary';
  static const String sales = '/sales';
  static const String saleReturns = '/sales-returns';
  static const String saleReturnInvoices = '/sales-returns/invoices';
  static String saleReturn(int id) => '/sales-returns/$id';
  static String deleteSaleReturn(int id) => '/sales-returns/$id';

  // POS
  static const String products = '/pos/products';
  static String productPrice(int productId) => '/pos/products/$productId/get-price';
  static const String calculateCart = '/pos/calculate-cart';
  static const String checkout = '/pos/checkout';
  static const String hold = '/pos/hold';
  static const String heldList = '/pos/held-list';
  static String recall(int id) => '/pos/recall/$id';
  static String voidSale(int id) => '/pos/void/$id';
  static const String customerReceivables = '/pos/receivables';
  static const String storeReceivablePayment = '/pos/receivables/payment';
  static String receivablePayments(int saleId) => '/pos/sales/$saleId/payments';

  // Shift
  static const String currentShift = '/shifts/current';
  static const String openShift = '/shifts/open';
  static String closeShift(int id) => '/shifts/$id/close';
  static String addExpense(int id) => '/shifts/$id/expenses';
  static String deleteExpense(int shiftId, int expenseId) => '/shifts/$shiftId/expenses/$expenseId';

  // Master Data & Store Settings
  static const String masterSummary = '/master-summary';
  static const String storeProduct = '/products';
  static String updateProduct(int id) => '/products/$id';
  static String deleteProduct(int id) => '/products/$id';
  static const String categories = '/categories';
  static String updateCategory(int id) => '/categories/$id';
  static String deleteCategory(int id) => '/categories/$id';
  static const String warehouses = '/warehouses';
  static String updateWarehouse(int id) => '/warehouses/$id';
  static String deleteWarehouse(int id) => '/warehouses/$id';
  static const String customers = '/customers';
  static String updateCustomer(int id) => '/customers/$id';
  static String deleteCustomer(int id) => '/customers/$id';
  static const String customerGroups = '/customer-groups';
  static const String units = '/units';
  static String updateUnit(int id) => '/units/$id';
  static String deleteUnit(int id) => '/units/$id';
  static const String suppliers = '/suppliers';
  static String updateSupplier(int id) => '/suppliers/$id';
  static String deleteSupplier(int id) => '/suppliers/$id';
  static const String discounts = '/discounts';
  static String updateDiscount(int id) => '/discounts/$id';
  static String deleteDiscount(int id) => '/discounts/$id';
  static const String accounts = '/accounts';
  static String updateAccount(int id) => '/accounts/$id';
  static String deleteAccount(int id) => '/accounts/$id';
  static String accountMutations(int id) => '/accounts/$id/mutations';
  static const String ppobProducts = '/ppob-products';
  static String updatePpobProduct(int id) => '/ppob-products/$id';
  static String deletePpobProduct(int id) => '/ppob-products/$id';
  static const String tables = '/tables';
  static String updateTable(int id) => '/tables/$id';
  static String deleteTable(int id) => '/tables/$id';
  static const String modifiers = '/modifiers';
  static const String receiptSettings = '/settings/receipt';

  // Purchasing & Pengadaan
  static const String purchaseOrders = '/purchases/orders';
  static String purchaseOrder(int id) => '/purchases/orders/$id';
  static String updatePurchaseOrder(int id) => '/purchases/orders/$id';
  static String updatePurchaseOrderStatus(int id) => '/purchases/orders/$id/status';
  static String deletePurchaseOrder(int id) => '/purchases/orders/$id';
  static const String purchaseReceipts = '/purchases/receipts';
  static const String purchaseReturns = '/purchases/returns';
  static String purchaseReturn(int id) => '/purchases/returns/$id';
  static String deletePurchaseReturn(int id) => '/purchases/returns/$id';
  static const String purchasePayables = '/purchases/payables';
  static const String storePayablePayment = '/purchases/payables/payment';
  static String payablePayments(int receiptId) => '/purchases/receipts/$receiptId/payments';
  static String deletePayment(int paymentId) => '/purchases/payments/$paymentId';

  // Inventaris & Kartu Stok (FIFO) & Peringatan Stok
  static const String stockAlerts = '/stocks/alerts';
  static const String stockMovements = '/stocks/movements';
  static const String stockBatches = '/stocks/batches';
  static String productStockCard(int productId) => '/stocks/products/$productId';

  // Stok Opname & Audit Inventaris
  static const String stockOpnames = '/stocks/opnames';
  static String stockOpname(int id) => '/stocks/opnames/$id';
  static String updateStockOpname(int id) => '/stocks/opnames/$id';
  static String approveStockOpname(int id) => '/stocks/opnames/$id/approve';
  static String deleteStockOpname(int id) => '/stocks/opnames/$id';

  // Transfer Antar Gudang
  static const String stockTransfers = '/stocks/transfers';
  static String stockTransfer(int id) => '/stocks/transfers/$id';
  static String dispatchStockTransfer(int id) => '/stocks/transfers/$id/dispatch';
  static String receiveStockTransfer(int id) => '/stocks/transfers/$id/receive';
  static String deleteStockTransfer(int id) => '/stocks/transfers/$id';

  // Penyesuaian Stok (Stock Adjustments)
  static const String stockAdjustments = '/stocks/adjustments';
  static String stockAdjustment(int id) => '/stocks/adjustments/$id';
  static String updateStockAdjustment(int id) => '/stocks/adjustments/$id';
  static String approveStockAdjustment(int id) => '/stocks/adjustments/$id/approve';
  static String deleteStockAdjustment(int id) => '/stocks/adjustments/$id';

  // Buku Arus Kas Masuk & Kas Keluar (Cash Flow)
  static const String cashFlows = '/cash-flows';
  static const String cashFlowCategories = '/cash-flows/categories';
  static String cashFlow(int id) => '/cash-flows/$id';
  static String updateCashFlow(int id) => '/cash-flows/$id';
  static String deleteCashFlow(int id) => '/cash-flows/$id';

  // Transfer Antar Kas & Bank (Account Transfers)
  static const String accountTransfers = '/account-transfers';
  static const String storeAccountTransfer = '/account-transfers';
  static String accountTransfer(int id) => '/account-transfers/$id';
}
