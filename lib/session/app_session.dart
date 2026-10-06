import '../models/lookup_item.dart';

class AppSession {
  AppSession._();

  static final AppSession instance = AppSession._();

  String? token;
  String? username;
  bool requireChangePassword = false;
  LookupItem? company;
  LookupItem? branch;
  LookupItem? period;

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  int? get ccode => company?.id;
  int? get bcode => branch?.id;
  int? get pid => period?.id;

  void clear() {
    token = null;
    username = null;
    requireChangePassword = false;
    company = null;
    branch = null;
    period = null;
  }
}
