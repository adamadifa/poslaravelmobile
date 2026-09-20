class StoreSettingsModel {
  final StoreProfileModel profile;
  final BusinessTypeSettingsModel businessType;
  final PrefixesSettingsModel prefixes;
  final TaxCurrencySettingsModel taxCurrency;
  final ReceiptTemplateSettingsModel receipt;
  final AgentSettingsModel agent;

  StoreSettingsModel({
    required this.profile,
    required this.businessType,
    required this.prefixes,
    required this.taxCurrency,
    required this.receipt,
    required this.agent,
  });

  factory StoreSettingsModel.fromJson(Map<String, dynamic> json) {
    return StoreSettingsModel(
      profile: StoreProfileModel.fromJson(json['profile'] as Map<String, dynamic>? ?? {}),
      businessType: BusinessTypeSettingsModel.fromJson(json['business_type'] as Map<String, dynamic>? ?? {}),
      prefixes: PrefixesSettingsModel.fromJson(json['prefixes'] as Map<String, dynamic>? ?? {}),
      taxCurrency: TaxCurrencySettingsModel.fromJson(json['tax_currency'] as Map<String, dynamic>? ?? {}),
      receipt: ReceiptTemplateSettingsModel.fromJson(json['receipt'] as Map<String, dynamic>? ?? {}),
      agent: AgentSettingsModel.fromJson(json['agent'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class StoreProfileModel {
  final String companyName;
  final String companyTagline;
  final String companyAddress;
  final String companyPhone;
  final String companyEmail;
  final String companyNpwp;
  final String? companyLogo;
  final String? companyLogoUrl;

  StoreProfileModel({
    required this.companyName,
    required this.companyTagline,
    required this.companyAddress,
    required this.companyPhone,
    required this.companyEmail,
    required this.companyNpwp,
    this.companyLogo,
    this.companyLogoUrl,
  });

  factory StoreProfileModel.fromJson(Map<String, dynamic> json) {
    return StoreProfileModel(
      companyName: json['company_name'] as String? ?? 'WarungPro',
      companyTagline: json['company_tagline'] as String? ?? '',
      companyAddress: json['company_address'] as String? ?? '',
      companyPhone: json['company_phone'] as String? ?? '',
      companyEmail: json['company_email'] as String? ?? '',
      companyNpwp: json['company_npwp'] as String? ?? '',
      companyLogo: json['company_logo'] as String?,
      companyLogoUrl: json['company_logo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'company_name': companyName,
    'company_tagline': companyTagline,
    'company_address': companyAddress,
    'company_phone': companyPhone,
    'company_email': companyEmail,
    'company_npwp': companyNpwp,
  };
}

class BusinessTypeSettingsModel {
  final String businessType; // 'retail', 'fnb', 'service', 'hybrid'
  final bool posAllowManualPriceEdit;

  // FNB
  final bool fnbEnableTableManagement;
  final bool fnbEnableKitchenDisplay;
  final bool fnbEnableModifiers;
  final bool fnbEnableReservation;
  final String fnbDefaultServiceType; // 'dine_in', 'take_away'
  final double fnbServiceChargePercent;
  final bool fnbAutoPrintKitchenTicket;
  final bool fnbEnableQueueNumber;

  // Service
  final bool serviceEnableBooking;
  final bool serviceEnableTechnicianAssignment;
  final bool serviceEnableDurationTracking;
  final int serviceBookingSlotMinutes;
  final bool serviceAutoQueue;
  final bool serviceEnableMaterialUsage;

  BusinessTypeSettingsModel({
    required this.businessType,
    required this.posAllowManualPriceEdit,
    required this.fnbEnableTableManagement,
    required this.fnbEnableKitchenDisplay,
    required this.fnbEnableModifiers,
    required this.fnbEnableReservation,
    required this.fnbDefaultServiceType,
    required this.fnbServiceChargePercent,
    required this.fnbAutoPrintKitchenTicket,
    required this.fnbEnableQueueNumber,
    required this.serviceEnableBooking,
    required this.serviceEnableTechnicianAssignment,
    required this.serviceEnableDurationTracking,
    required this.serviceBookingSlotMinutes,
    required this.serviceAutoQueue,
    required this.serviceEnableMaterialUsage,
  });

  factory BusinessTypeSettingsModel.fromJson(Map<String, dynamic> json) {
    return BusinessTypeSettingsModel(
      businessType: json['business_type'] as String? ?? 'retail',
      posAllowManualPriceEdit: json['pos_allow_manual_price_edit'] as bool? ?? true,
      fnbEnableTableManagement: json['fnb_enable_table_management'] as bool? ?? true,
      fnbEnableKitchenDisplay: json['fnb_enable_kitchen_display'] as bool? ?? true,
      fnbEnableModifiers: json['fnb_enable_modifiers'] as bool? ?? true,
      fnbEnableReservation: json['fnb_enable_reservation'] as bool? ?? true,
      fnbDefaultServiceType: json['fnb_default_service_type'] as String? ?? 'dine_in',
      fnbServiceChargePercent: (json['fnb_service_charge_percent'] as num?)?.toDouble() ?? 0.0,
      fnbAutoPrintKitchenTicket: json['fnb_auto_print_kitchen_ticket'] as bool? ?? false,
      fnbEnableQueueNumber: json['fnb_enable_queue_number'] as bool? ?? true,
      serviceEnableBooking: json['service_enable_booking'] as bool? ?? true,
      serviceEnableTechnicianAssignment: json['service_enable_technician_assignment'] as bool? ?? true,
      serviceEnableDurationTracking: json['service_enable_duration_tracking'] as bool? ?? true,
      serviceBookingSlotMinutes: json['service_booking_slot_minutes'] as int? ?? 30,
      serviceAutoQueue: json['service_auto_queue'] as bool? ?? true,
      serviceEnableMaterialUsage: json['service_enable_material_usage'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'business_type': businessType,
    'pos_allow_manual_price_edit': posAllowManualPriceEdit,
    'fnb_enable_table_management': fnbEnableTableManagement,
    'fnb_enable_kitchen_display': fnbEnableKitchenDisplay,
    'fnb_enable_modifiers': fnbEnableModifiers,
    'fnb_enable_reservation': fnbEnableReservation,
    'fnb_default_service_type': fnbDefaultServiceType,
    'fnb_service_charge_percent': fnbServiceChargePercent,
    'fnb_auto_print_kitchen_ticket': fnbAutoPrintKitchenTicket,
    'fnb_enable_queue_number': fnbEnableQueueNumber,
    'service_enable_booking': serviceEnableBooking,
    'service_enable_technician_assignment': serviceEnableTechnicianAssignment,
    'service_enable_duration_tracking': serviceEnableDurationTracking,
    'service_booking_slot_minutes': serviceBookingSlotMinutes,
    'service_auto_queue': serviceAutoQueue,
    'service_enable_material_usage': serviceEnableMaterialUsage,
  };
}

class PrefixesSettingsModel {
  final String prefixInvoice;
  final String prefixPo;
  final String prefixGrn;
  final String prefixReturnSale;
  final String prefixReturnPurchase;
  final String prefixOpname;
  final String prefixTransfer;

  PrefixesSettingsModel({
    required this.prefixInvoice,
    required this.prefixPo,
    required this.prefixGrn,
    required this.prefixReturnSale,
    required this.prefixReturnPurchase,
    required this.prefixOpname,
    required this.prefixTransfer,
  });

  factory PrefixesSettingsModel.fromJson(Map<String, dynamic> json) {
    return PrefixesSettingsModel(
      prefixInvoice: json['prefix_invoice'] as String? ?? 'INV',
      prefixPo: json['prefix_po'] as String? ?? 'PO',
      prefixGrn: json['prefix_grn'] as String? ?? 'GRN',
      prefixReturnSale: json['prefix_return_sale'] as String? ?? 'SR',
      prefixReturnPurchase: json['prefix_return_purchase'] as String? ?? 'PR',
      prefixOpname: json['prefix_opname'] as String? ?? 'SO',
      prefixTransfer: json['prefix_transfer'] as String? ?? 'TF',
    );
  }

  Map<String, dynamic> toJson() => {
    'prefix_invoice': prefixInvoice,
    'prefix_po': prefixPo,
    'prefix_grn': prefixGrn,
    'prefix_return_sale': prefixReturnSale,
    'prefix_return_purchase': prefixReturnPurchase,
    'prefix_opname': prefixOpname,
    'prefix_transfer': prefixTransfer,
  };
}

class TaxCurrencySettingsModel {
  final double defaultTaxRate;
  final String currencySymbol;
  final String currencyCode;

  TaxCurrencySettingsModel({
    required this.defaultTaxRate,
    required this.currencySymbol,
    required this.currencyCode,
  });

  factory TaxCurrencySettingsModel.fromJson(Map<String, dynamic> json) {
    return TaxCurrencySettingsModel(
      defaultTaxRate: (json['default_tax_rate'] as num?)?.toDouble() ?? 11.0,
      currencySymbol: json['currency_symbol'] as String? ?? 'Rp',
      currencyCode: json['currency_code'] as String? ?? 'IDR',
    );
  }

  Map<String, dynamic> toJson() => {
    'default_tax_rate': defaultTaxRate,
    'currency_symbol': currencySymbol,
    'currency_code': currencyCode,
  };
}

class ReceiptTemplateSettingsModel {
  final String receiptHeader;
  final String receiptFooter;
  final String receiptPaperSize; // '58mm', '80mm'
  final bool receiptShowLogo;

  ReceiptTemplateSettingsModel({
    required this.receiptHeader,
    required this.receiptFooter,
    required this.receiptPaperSize,
    required this.receiptShowLogo,
  });

  factory ReceiptTemplateSettingsModel.fromJson(Map<String, dynamic> json) {
    return ReceiptTemplateSettingsModel(
      receiptHeader: json['receipt_header'] as String? ?? '',
      receiptFooter: json['receipt_footer'] as String? ?? '',
      receiptPaperSize: json['receipt_paper_size'] as String? ?? '58mm',
      receiptShowLogo: json['receipt_show_logo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'receipt_header': receiptHeader,
    'receipt_footer': receiptFooter,
    'receipt_paper_size': receiptPaperSize,
    'receipt_show_logo': receiptShowLogo,
  };
}

class AdminFeeTierModel {
  final double min;
  final double max;
  final double fee;

  AdminFeeTierModel({
    required this.min,
    required this.max,
    required this.fee,
  });

  factory AdminFeeTierModel.fromJson(Map<String, dynamic> json) {
    return AdminFeeTierModel(
      min: (json['min'] as num?)?.toDouble() ?? 0.0,
      max: (json['max'] as num?)?.toDouble() ?? 0.0,
      fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'min': min,
    'max': max,
    'fee': fee,
  };
}

class AgentSettingsModel {
  final double agentTransferAdminFee;
  final double agentWithdrawAdminFee;
  final List<AdminFeeTierModel> transferTiers;
  final List<AdminFeeTierModel> withdrawTiers;

  AgentSettingsModel({
    required this.agentTransferAdminFee,
    required this.agentWithdrawAdminFee,
    required this.transferTiers,
    required this.withdrawTiers,
  });

  factory AgentSettingsModel.fromJson(Map<String, dynamic> json) {
    final transferTiersList = (json['transfer_tiers'] as List<dynamic>?)
            ?.map((e) => AdminFeeTierModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final withdrawTiersList = (json['withdraw_tiers'] as List<dynamic>?)
            ?.map((e) => AdminFeeTierModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return AgentSettingsModel(
      agentTransferAdminFee: (json['agent_transfer_admin_fee'] as num?)?.toDouble() ?? 5000.0,
      agentWithdrawAdminFee: (json['agent_withdraw_admin_fee'] as num?)?.toDouble() ?? 5000.0,
      transferTiers: transferTiersList,
      withdrawTiers: withdrawTiersList,
    );
  }

  Map<String, dynamic> toJson() => {
    'agent_transfer_admin_fee': agentTransferAdminFee,
    'agent_withdraw_admin_fee': agentWithdrawAdminFee,
    'transfer_tiers': transferTiers.map((e) => e.toJson()).toList(),
    'withdraw_tiers': withdrawTiers.map((e) => e.toJson()).toList(),
  };
}
