class ApiConfig {
  static const String baseUrl = 'http://empirvps2.staritcloud.com:8071';

  static const String login = '/api/Login';
  static const String forgotPassword = '/api/Login/ForgotPassword';
  static const String verifyOtp = '/api/Login/VerifyOtp';
  static const String resetPassword = '/api/Login/ResetPassword';
  static const String loginContext = '/api/Login/Context';
  static const String logout = '/api/Login/Logout';
  static const String company = '/api/Company';
  static const String branch = '/api/Branch';
  static const String period = '/api/Period';
  static const String mobileDashboardCounts = '/api/MobileDashboard/Counts';
  static const String mobileDashboardOutstanding =
      '/api/MobileDashboard/Outstanding';
  static const String mobileCityOutstanding = '/api/MobileCityOutstanding';
  static const String dashboard = '/api/Dashboard';
  static const String dashboardAvailableFunds = '/api/Dashboard/AvailableFunds';
  static const String dashboardNetReceivablePayable =
      '/api/Dashboard/NetReceivablePayable';
  static const String dashboardPendingOrders = '/api/Dashboard/PendingOrders';
  static const String dashboardTotalDelivery = '/api/Dashboard/TotalDelivery';
  static const String dashboardCashBankFlowIn = '/api/Dashboard/CashBankFlowIn';
  static const String dashboardCashBankFlowOut =
      '/api/Dashboard/CashBankFlowOut';
  static const String dashboardTotalSales = '/api/Dashboard/TotalSales';
  static const String dashboardSalesByCategory =
      '/api/Dashboard/SalesByCategory';
  static const String dashboardDailyReceived = '/api/Dashboard/DailyReceived';
  static const String dashboardPartyReceivablesPayables =
      '/api/Dashboard/PartyReceivablesPayables';
  static const String dashboardPendingSaleOrders =
      '/api/Dashboard/PendingSaleOrders';
  static const String dashboardStockMovement = '/api/Dashboard/StockMovement';
  static const String sodaBookFeeding = '/api/SodaBookFeeding';
  static const String sodaBookFeedingQuickSearch =
      '/api/SodaBookFeeding/QuickSearch';
  static const String sodaBookFeedingStatuses = '/api/SodaBookFeeding/Statuses';
  static const String sodaBookFeedingMovements =
      '/api/SodaBookFeeding/Movements';
  static const String sodaBookFeedingParties = '/api/SodaBookFeeding/Parties';
  static const String sodaBookFeedingConditions =
      '/api/SodaBookFeeding/Conditions';
  static const String sodaBookFeedingTypes = '/api/SodaBookFeeding/Types';
  static const String sodaBookFeedingCurrencies =
      '/api/SodaBookFeeding/Currencies';
  static const String sodaBookFeedingUnits = '/api/SodaBookFeeding/Units';
  static const String sodaBookFeedingSodaTypes =
      '/api/SodaBookFeeding/SodaTypes';
  static const String sodaBookFeedingItems = '/api/SodaBookFeeding/Items';
  static const String sodaBookFeedingRtTypes = '/api/SodaBookFeeding/RtTypes';
}
