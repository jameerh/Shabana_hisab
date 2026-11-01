import 'dart:convert';
import 'package:intl/intl.dart';
import '../../core/utils/date_utils.dart';
export '../../core/utils/date_utils.dart';

// ==========================================
// ENUMS & EXTENSIONS
// ==========================================

enum GadiVehicleType {
  bike,
  car,
  auto,
  truck,
  tractor,
  ev,
  other,
}

extension GadiVehicleTypeExtension on GadiVehicleType {
  String get name {
    switch (this) {
      case GadiVehicleType.bike: return 'bike';
      case GadiVehicleType.car: return 'car';
      case GadiVehicleType.auto: return 'auto';
      case GadiVehicleType.truck: return 'truck';
      case GadiVehicleType.tractor: return 'tractor';
      case GadiVehicleType.ev: return 'ev';
      case GadiVehicleType.other: return 'other';
    }
  }

  String get englishLabel {
    switch (this) {
      case GadiVehicleType.bike: return 'Bike / Two-Wheeler';
      case GadiVehicleType.car: return 'Car / Four-Wheeler';
      case GadiVehicleType.auto: return 'Auto Rickshaw (3W)';
      case GadiVehicleType.truck: return 'Truck / Commercial';
      case GadiVehicleType.tractor: return 'Tractor / Agri';
      case GadiVehicleType.ev: return 'Electric Vehicle (EV)';
      case GadiVehicleType.other: return 'Other Vehicle';
    }
  }

  String get marathiLabel {
    switch (this) {
      case GadiVehicleType.bike: return 'बाईक / दुचाकी';
      case GadiVehicleType.car: return 'कार / चारचाकी';
      case GadiVehicleType.auto: return 'रिक्षा / तीनचाकी';
      case GadiVehicleType.truck: return 'ट्रक / कमर्शियल';
      case GadiVehicleType.tractor: return 'ट्रॅक्टर / शेती';
      case GadiVehicleType.ev: return 'इलेक्ट्रिक वाहन (EV)';
      case GadiVehicleType.other: return 'इतर वाहन';
    }
  }

  String get emoji {
    switch (this) {
      case GadiVehicleType.bike: return '🏍️';
      case GadiVehicleType.car: return '🚗';
      case GadiVehicleType.auto: return '🛺';
      case GadiVehicleType.truck: return '🚚';
      case GadiVehicleType.tractor: return '🚜';
      case GadiVehicleType.ev: return '⚡';
      case GadiVehicleType.other: return '🚙';
    }
  }

  static GadiVehicleType fromString(String val) {
    return GadiVehicleType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => GadiVehicleType.car,
    );
  }
}

enum GadiFuelType {
  petrol,
  diesel,
  cng,
  electric,
  hybrid,
  lpg,
}

extension GadiFuelTypeExtension on GadiFuelType {
  String get name {
    switch (this) {
      case GadiFuelType.petrol: return 'petrol';
      case GadiFuelType.diesel: return 'diesel';
      case GadiFuelType.cng: return 'cng';
      case GadiFuelType.electric: return 'electric';
      case GadiFuelType.hybrid: return 'hybrid';
      case GadiFuelType.lpg: return 'lpg';
    }
  }

  String get unit {
    switch (this) {
      case GadiFuelType.petrol:
      case GadiFuelType.diesel:
      case GadiFuelType.hybrid:
      case GadiFuelType.lpg:
        return 'L';
      case GadiFuelType.cng:
        return 'kg';
      case GadiFuelType.electric:
        return 'kWh';
    }
  }

  String get mileageUnit {
    switch (this) {
      case GadiFuelType.petrol:
      case GadiFuelType.diesel:
      case GadiFuelType.hybrid:
      case GadiFuelType.lpg:
        return 'KM/L';
      case GadiFuelType.cng:
        return 'KM/kg';
      case GadiFuelType.electric:
        return 'KM/kWh';
    }
  }

  String get englishLabel {
    switch (this) {
      case GadiFuelType.petrol: return 'Petrol';
      case GadiFuelType.diesel: return 'Diesel';
      case GadiFuelType.cng: return 'CNG';
      case GadiFuelType.electric: return 'Electric';
      case GadiFuelType.hybrid: return 'Hybrid';
      case GadiFuelType.lpg: return 'LPG';
    }
  }

  String get marathiLabel {
    switch (this) {
      case GadiFuelType.petrol: return 'पेट्रोल';
      case GadiFuelType.diesel: return 'डिझेल';
      case GadiFuelType.cng: return 'सीएनजी (CNG)';
      case GadiFuelType.electric: return 'इलेक्ट्रिक';
      case GadiFuelType.hybrid: return 'हायब्रिड';
      case GadiFuelType.lpg: return 'एलपीजी (LPG)';
    }
  }

  String get emoji {
    switch (this) {
      case GadiFuelType.petrol: return '⛽';
      case GadiFuelType.diesel: return '🛢️';
      case GadiFuelType.cng: return '💨';
      case GadiFuelType.electric: return '🔋';
      case GadiFuelType.hybrid: return '🌱';
      case GadiFuelType.lpg: return '🔥';
    }
  }

  static GadiFuelType fromString(String val) {
    return GadiFuelType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => GadiFuelType.petrol,
    );
  }
}

enum GadiEventType {
  fuel,
  service,
  repair,
  emi,
  accident,
  claim,
  challan,
  toll,
  parking,
  washing,
  accessory,
  labour,
  problem,
  other,
}

extension GadiEventTypeExtension on GadiEventType {
  String get name {
    switch (this) {
      case GadiEventType.fuel: return 'fuel';
      case GadiEventType.service: return 'service';
      case GadiEventType.repair: return 'repair';
      case GadiEventType.emi: return 'emi';
      case GadiEventType.accident: return 'accident';
      case GadiEventType.claim: return 'claim';
      case GadiEventType.challan: return 'challan';
      case GadiEventType.toll: return 'toll';
      case GadiEventType.parking: return 'parking';
      case GadiEventType.washing: return 'washing';
      case GadiEventType.accessory: return 'accessory';
      case GadiEventType.labour: return 'labour';
      case GadiEventType.problem: return 'problem';
      case GadiEventType.other: return 'other';
    }
  }

  String get englishLabel {
    switch (this) {
      case GadiEventType.fuel: return 'Fuel Refill';
      case GadiEventType.service: return 'Scheduled Service';
      case GadiEventType.repair: return 'Garage Repair / Parts';
      case GadiEventType.emi: return 'Loan EMI';
      case GadiEventType.accident: return 'Accident / Damage';
      case GadiEventType.claim: return 'Insurance Claim';
      case GadiEventType.challan: return 'Traffic Challan / Fine';
      case GadiEventType.toll: return 'Toll / FASTag';
      case GadiEventType.parking: return 'Parking';
      case GadiEventType.washing: return 'Washing / Detailing';
      case GadiEventType.accessory: return 'Accessories / Gear';
      case GadiEventType.labour: return 'Driver / Labour';
      case GadiEventType.problem: return 'Vehicle Problem / Note';
      case GadiEventType.other: return 'Other Vehicle Expense';
    }
  }

  String get marathiLabel {
    switch (this) {
      case GadiEventType.fuel: return 'इंधन / पेट्रोल भरले';
      case GadiEventType.service: return 'सर्व्हिसिंग / मेंटेनन्स';
      case GadiEventType.repair: return 'दुरुस्ती / स्पेअर पार्ट';
      case GadiEventType.emi: return 'गाडीचा हप्ता (EMI)';
      case GadiEventType.accident: return 'अपघात / नुकसान';
      case GadiEventType.claim: return 'विमा क्लेम (Insurance)';
      case GadiEventType.challan: return 'ट्रॅफिक चलन / फाईन';
      case GadiEventType.toll: return 'टोल / फास्टॅग';
      case GadiEventType.parking: return 'पार्किंग';
      case GadiEventType.washing: return 'वॉशिंग / क्लीनिंग';
      case GadiEventType.accessory: return 'अ‍ॅक्सेसरी / साहित्य';
      case GadiEventType.labour: return 'ड्रायव्हर / हमाली';
      case GadiEventType.problem: return 'गाडीची तक्रार / समस्या';
      case GadiEventType.other: return 'इतर गाडी खर्च';
    }
  }

  String get emoji {
    switch (this) {
      case GadiEventType.fuel: return '⛽';
      case GadiEventType.service: return '🔧';
      case GadiEventType.repair: return '🛠️';
      case GadiEventType.emi: return '💳';
      case GadiEventType.accident: return '💥';
      case GadiEventType.claim: return '🛡️';
      case GadiEventType.challan: return '🚨';
      case GadiEventType.toll: return '🛣️';
      case GadiEventType.parking: return '🅿️';
      case GadiEventType.washing: return '🧼';
      case GadiEventType.accessory: return '🪖';
      case GadiEventType.labour: return '👨‍✈️';
      case GadiEventType.problem: return '⚠️';
      case GadiEventType.other: return '📝';
    }
  }

  bool get isFinancial => this != GadiEventType.problem;

  static GadiEventType fromString(String val) {
    return GadiEventType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => GadiEventType.other,
    );
  }
}

enum GadiTripType {
  personal,
  business,
  office,
  clientVisit,
  delivery,
  other,
}

extension GadiTripTypeExtension on GadiTripType {
  String get name {
    switch (this) {
      case GadiTripType.personal: return 'personal';
      case GadiTripType.business: return 'business';
      case GadiTripType.office: return 'office';
      case GadiTripType.clientVisit: return 'clientVisit';
      case GadiTripType.delivery: return 'delivery';
      case GadiTripType.other: return 'other';
    }
  }

  String get englishLabel {
    switch (this) {
      case GadiTripType.personal: return 'Personal Trip';
      case GadiTripType.business: return 'Business';
      case GadiTripType.office: return 'Office Commute';
      case GadiTripType.clientVisit: return 'Client Visit';
      case GadiTripType.delivery: return 'Customer Delivery';
      case GadiTripType.other: return 'Other Journey';
    }
  }

  String get marathiLabel {
    switch (this) {
      case GadiTripType.personal: return 'वैयक्तिक फेरी';
      case GadiTripType.business: return 'व्यवसाय / धंदा';
      case GadiTripType.office: return 'ऑफिस येणे-जाणे';
      case GadiTripType.clientVisit: return 'ग्राहक भेट';
      case GadiTripType.delivery: return 'माल डिलिव्हरी';
      case GadiTripType.other: return 'इतर प्रवास';
    }
  }

  String get emoji {
    switch (this) {
      case GadiTripType.personal: return '🏡';
      case GadiTripType.business: return '💼';
      case GadiTripType.office: return '🏢';
      case GadiTripType.clientVisit: return '🤝';
      case GadiTripType.delivery: return '📦';
      case GadiTripType.other: return '🚗';
    }
  }

  bool get isBusinessTrip =>
      this == GadiTripType.business ||
      this == GadiTripType.clientVisit ||
      this == GadiTripType.delivery ||
      this == GadiTripType.office;

  static GadiTripType fromString(String val) {
    return GadiTripType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => GadiTripType.personal,
    );
  }
}

enum GadiDueType {
  puc,
  insurance,
  serviceDate,
  serviceKm,
  roadTax,
  fitness,
  emi,
}

extension GadiDueTypeExtension on GadiDueType {
  String get name {
    switch (this) {
      case GadiDueType.puc: return 'puc';
      case GadiDueType.insurance: return 'insurance';
      case GadiDueType.serviceDate: return 'serviceDate';
      case GadiDueType.serviceKm: return 'serviceKm';
      case GadiDueType.roadTax: return 'roadTax';
      case GadiDueType.fitness: return 'fitness';
      case GadiDueType.emi: return 'emi';
    }
  }

  String get englishLabel {
    switch (this) {
      case GadiDueType.puc: return 'PUC Expiry';
      case GadiDueType.insurance: return 'Insurance Renewal';
      case GadiDueType.serviceDate: return 'Scheduled Service';
      case GadiDueType.serviceKm: return 'KM-based Service';
      case GadiDueType.roadTax: return 'Road Tax Renewal';
      case GadiDueType.fitness: return 'Fitness Certificate';
      case GadiDueType.emi: return 'Monthly Loan EMI';
    }
  }

  String get marathiLabel {
    switch (this) {
      case GadiDueType.puc: return 'पीयुसी संपण्याची तारीख';
      case GadiDueType.insurance: return 'विमा (Insurance) रिन्युअल';
      case GadiDueType.serviceDate: return 'सर्व्हिसिंग तारीख';
      case GadiDueType.serviceKm: return 'किमी (KM) सर्व्हिसिंग';
      case GadiDueType.roadTax: return 'रोड टॅक्स रिन्युअल';
      case GadiDueType.fitness: return 'फिटनेस सर्टिफिकेट';
      case GadiDueType.emi: return 'गाडीचा हप्ता (EMI)';
    }
  }

  String get emoji {
    switch (this) {
      case GadiDueType.puc: return '💨';
      case GadiDueType.insurance: return '🛡️';
      case GadiDueType.serviceDate: return '📅';
      case GadiDueType.serviceKm: return '⏱️';
      case GadiDueType.roadTax: return '🏛️';
      case GadiDueType.fitness: return '📋';
      case GadiDueType.emi: return '💳';
    }
  }

  static GadiDueType fromString(String val) {
    return GadiDueType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => GadiDueType.puc,
    );
  }
}

enum GadiDueStatus {
  pending,
  overdue,
  completed,
  snoozed,
}

enum GadiEvidenceType {
  petrolMeter,
  billReceipt,
  claimDoc,
  policeFir,
  estimate,
  rcBook,
  problemPhoto,
  other,
}

extension GadiEvidenceTypeExtension on GadiEvidenceType {
  String get name {
    switch (this) {
      case GadiEvidenceType.petrolMeter: return 'PETROL_METER';
      case GadiEvidenceType.billReceipt: return 'BILL_RECEIPT';
      case GadiEvidenceType.claimDoc: return 'CLAIM_DOC';
      case GadiEvidenceType.policeFir: return 'POLICE_FIR';
      case GadiEvidenceType.estimate: return 'ESTIMATE';
      case GadiEvidenceType.rcBook: return 'RC_BOOK';
      case GadiEvidenceType.problemPhoto: return 'PROBLEM_PHOTO';
      case GadiEvidenceType.other: return 'OTHER';
    }
  }

  static GadiEvidenceType fromString(String val) {
    return GadiEvidenceType.values.firstWhere(
      (e) => e.name.toUpperCase() == val.toUpperCase(),
      orElse: () => GadiEvidenceType.other,
    );
  }
}

// ==========================================
// STRONGLY TYPED JSON PAYLOADS
// ==========================================

class FuelPayload {
  final double quantity; // Liters, kg, or kWh
  final double ratePerUnit; // ₹ per liter or kg
  final bool isFullTank;
  final String? fuelStationName;
  final String? fuelType;

  FuelPayload({
    required this.quantity,
    required this.ratePerUnit,
    this.isFullTank = true,
    this.fuelStationName,
    this.fuelType,
  });

  Map<String, dynamic> toMap() => {
    'quantity': quantity,
    'rate_per_unit': ratePerUnit,
    'is_full_tank': isFullTank,
    'fuel_station_name': fuelStationName,
    'fuel_type': fuelType,
  };

  factory FuelPayload.fromMap(Map<String, dynamic> map) {
    return FuelPayload(
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      ratePerUnit: (map['rate_per_unit'] as num?)?.toDouble() ?? 0.0,
      isFullTank: map['is_full_tank'] as bool? ?? true,
      fuelStationName: map['fuel_station_name'] as String?,
      fuelType: map['fuel_type'] as String?,
    );
  }
}

class ServicePayload {
  final String? serviceCenterName;
  final bool engineOilReplaced;
  final String? oilGrade;
  final double partsCost;
  final double labourCost;
  final double taxCost;
  final double? nextServiceKmDue;
  final String? nextServiceDateDue;
  final List<String> replacedPartsList;

  ServicePayload({
    this.serviceCenterName,
    this.engineOilReplaced = false,
    this.oilGrade,
    this.partsCost = 0.0,
    this.labourCost = 0.0,
    this.taxCost = 0.0,
    this.nextServiceKmDue,
    this.nextServiceDateDue,
    this.replacedPartsList = const [],
  });

  Map<String, dynamic> toMap() => {
    'service_center_name': serviceCenterName,
    'engine_oil_replaced': engineOilReplaced,
    'oil_grade': oilGrade,
    'parts_cost': partsCost,
    'labour_cost': labourCost,
    'tax_cost': taxCost,
    'next_service_km_due': nextServiceKmDue,
    'next_service_date_due': nextServiceDateDue,
    'replaced_parts_list': replacedPartsList,
  };

  factory ServicePayload.fromMap(Map<String, dynamic> map) {
    return ServicePayload(
      serviceCenterName: map['service_center_name'] as String?,
      engineOilReplaced: map['engine_oil_replaced'] as bool? ?? false,
      oilGrade: map['oil_grade'] as String?,
      partsCost: (map['parts_cost'] as num?)?.toDouble() ?? 0.0,
      labourCost: (map['labour_cost'] as num?)?.toDouble() ?? 0.0,
      taxCost: (map['tax_cost'] as num?)?.toDouble() ?? 0.0,
      nextServiceKmDue: (map['next_service_km_due'] as num?)?.toDouble(),
      nextServiceDateDue: map['next_service_date_due'] as String?,
      replacedPartsList: (map['replaced_parts_list'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class RepairPayload {
  final String? garageName;
  final String? mechanicName;
  final String? mechanicPhone;
  final String? issueDescription;
  final String? diagnosticFindings;
  final List<String> replacedParts;
  final int? warrantyMonths;

  RepairPayload({
    this.garageName,
    this.mechanicName,
    this.mechanicPhone,
    this.issueDescription,
    this.diagnosticFindings,
    this.replacedParts = const [],
    this.warrantyMonths,
  });

  Map<String, dynamic> toMap() => {
    'garage_name': garageName,
    'mechanic_name': mechanicName,
    'mechanic_phone': mechanicPhone,
    'issue_description': issueDescription,
    'diagnostic_findings': diagnosticFindings,
    'replaced_parts': replacedParts,
    'warranty_months': warrantyMonths,
  };

  factory RepairPayload.fromMap(Map<String, dynamic> map) {
    return RepairPayload(
      garageName: map['garage_name'] as String?,
      mechanicName: map['mechanic_name'] as String?,
      mechanicPhone: map['mechanic_phone'] as String?,
      issueDescription: map['issue_description'] as String?,
      diagnosticFindings: map['diagnostic_findings'] as String?,
      replacedParts: (map['replaced_parts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      warrantyMonths: (map['warranty_months'] as num?)?.toInt(),
    );
  }
}

class EmiPayload {
  final int? installmentNumber;
  final int? totalInstallments;
  final double? principalPortion;
  final double? interestPortion;
  final String? bankName;
  final String? loanAccountNumber;
  final double? remainingPrincipal;

  EmiPayload({
    this.installmentNumber,
    this.totalInstallments,
    this.principalPortion,
    this.interestPortion,
    this.bankName,
    this.loanAccountNumber,
    this.remainingPrincipal,
  });

  Map<String, dynamic> toMap() => {
    'installment_number': installmentNumber,
    'total_installments': totalInstallments,
    'principal_portion': principalPortion,
    'interest_portion': interestPortion,
    'bank_name': bankName,
    'loan_account_number': loanAccountNumber,
    'remaining_principal': remainingPrincipal,
  };

  factory EmiPayload.fromMap(Map<String, dynamic> map) {
    return EmiPayload(
      installmentNumber: (map['installment_number'] as num?)?.toInt(),
      totalInstallments: (map['total_installments'] as num?)?.toInt(),
      principalPortion: (map['principal_portion'] as num?)?.toDouble(),
      interestPortion: (map['interest_portion'] as num?)?.toDouble(),
      bankName: map['bank_name'] as String?,
      loanAccountNumber: map['loan_account_number'] as String?,
      remainingPrincipal: (map['remaining_principal'] as num?)?.toDouble(),
    );
  }
}

class AccidentClaimPayload {
  final String? accidentDate;
  final String? accidentLocation;
  final bool thirdPartyInvolved;
  final String? firNumber;
  final String? policeStation;
  final String? insuranceCompany;
  final String? claimNumber;
  final String? surveyorName;
  final String? surveyorPhone;
  final double estimatedLossAmount;
  final double approvedAmount;
  final double outOfPocketAmount;
  final String claimStatus;

  AccidentClaimPayload({
    this.accidentDate,
    this.accidentLocation,
    this.thirdPartyInvolved = false,
    this.firNumber,
    this.policeStation,
    this.insuranceCompany,
    this.claimNumber,
    this.surveyorName,
    this.surveyorPhone,
    this.estimatedLossAmount = 0.0,
    this.approvedAmount = 0.0,
    this.outOfPocketAmount = 0.0,
    this.claimStatus = 'REPORTED',
  });

  Map<String, dynamic> toMap() => {
    'accident_date': accidentDate,
    'accident_location': accidentLocation,
    'third_party_involved': thirdPartyInvolved,
    'fir_number': firNumber,
    'police_station': policeStation,
    'insurance_company': insuranceCompany,
    'claim_number': claimNumber,
    'surveyor_name': surveyorName,
    'surveyor_phone': surveyorPhone,
    'estimated_loss_amount': estimatedLossAmount,
    'approved_amount': approvedAmount,
    'out_of_pocket_amount': outOfPocketAmount,
    'claim_status': claimStatus,
  };

  factory AccidentClaimPayload.fromMap(Map<String, dynamic> map) {
    return AccidentClaimPayload(
      accidentDate: map['accident_date'] as String?,
      accidentLocation: map['accident_location'] as String?,
      thirdPartyInvolved: map['third_party_involved'] as bool? ?? false,
      firNumber: map['fir_number'] as String?,
      policeStation: map['police_station'] as String?,
      insuranceCompany: map['insurance_company'] as String?,
      claimNumber: map['claim_number'] as String?,
      surveyorName: map['surveyor_name'] as String?,
      surveyorPhone: map['surveyor_phone'] as String?,
      estimatedLossAmount: (map['estimated_loss_amount'] as num?)?.toDouble() ?? 0.0,
      approvedAmount: (map['approved_amount'] as num?)?.toDouble() ?? 0.0,
      outOfPocketAmount: (map['out_of_pocket_amount'] as num?)?.toDouble() ?? 0.0,
      claimStatus: map['claim_status'] as String? ?? 'REPORTED',
    );
  }
}

class ChallanPayload {
  final String? challanNumber;
  final String? violationLocation;
  final String? violationReason;
  final String status;

  ChallanPayload({
    this.challanNumber,
    this.violationLocation,
    this.violationReason,
    this.status = 'PAID',
  });

  Map<String, dynamic> toMap() => {
    'challan_number': challanNumber,
    'violation_location': violationLocation,
    'violation_reason': violationReason,
    'status': status,
  };

  factory ChallanPayload.fromMap(Map<String, dynamic> map) {
    return ChallanPayload(
      challanNumber: map['challan_number'] as String?,
      violationLocation: map['violation_location'] as String?,
      violationReason: map['violation_reason'] as String?,
      status: map['status'] as String? ?? 'PAID',
    );
  }
}

// ==========================================
// DOMAIN ENTITIES
// ==========================================

class GadiVehicle {
  final int id;
  final int profileId;
  final String name;
  final GadiVehicleType vehicleType;
  final String registrationNumber;
  final GadiFuelType fuelType;
  final double initialOdometer;
  final double currentOdometer;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final double? downPayment;
  final double defaultReimbursementRate;
  final String? chassisNumber;
  final String? engineNumber;
  final String? insurancePolicyNumber;
  final DateTime? insuranceExpiryDate;
  final DateTime? pucExpiryDate;
  final DateTime? fitnessExpiryDate;
  final DateTime? roadTaxExpiryDate;
  final DateTime? serviceDueDate;
  final double? serviceDueKm;
  final double? serviceIntervalKm;
  final int? serviceIntervalMonths;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GadiVehicle({
    required this.id,
    required this.profileId,
    required this.name,
    required this.vehicleType,
    required this.registrationNumber,
    required this.fuelType,
    this.initialOdometer = 0.0,
    this.currentOdometer = 0.0,
    this.purchaseDate,
    this.purchasePrice,
    this.downPayment,
    this.defaultReimbursementRate = 0.0,
    this.chassisNumber,
    this.engineNumber,
    this.insurancePolicyNumber,
    this.insuranceExpiryDate,
    this.pucExpiryDate,
    this.fitnessExpiryDate,
    this.roadTaxExpiryDate,
    this.serviceDueDate,
    this.serviceDueKm,
    this.serviceIntervalKm,
    this.serviceIntervalMonths,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayTitle => '$name ($registrationNumber)';

  bool get isBike => vehicleType == GadiVehicleType.bike;
  bool get isCar => vehicleType == GadiVehicleType.car;
  bool get isEv => fuelType == GadiFuelType.electric;

  Map<String, dynamic> toMap() => {
    if (id > 0) 'id': id,
    'profile_id': profileId,
    'name': name,
    'vehicle_type': vehicleType.name,
    'registration_number': registrationNumber,
    'fuel_type': fuelType.name,
    'initial_odometer': initialOdometer,
    'current_odometer': currentOdometer,
    'purchase_date': purchaseDate?.toIso8601String(),
    'purchase_price': purchasePrice,
    'down_payment': downPayment,
    'default_reimbursement_rate': defaultReimbursementRate,
    'chassis_number': chassisNumber,
    'engine_number': engineNumber,
    'insurance_policy_number': insurancePolicyNumber,
    'insurance_expiry_date': insuranceExpiryDate?.toIso8601String(),
    'puc_expiry_date': pucExpiryDate?.toIso8601String(),
    'fitness_expiry_date': fitnessExpiryDate?.toIso8601String(),
    'road_tax_expiry_date': roadTaxExpiryDate?.toIso8601String(),
    'service_due_date': serviceDueDate?.toIso8601String(),
    'service_due_km': serviceDueKm,
    'service_interval_km': serviceIntervalKm,
    'service_interval_months': serviceIntervalMonths,
    'is_active': isActive ? 1 : 0,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory GadiVehicle.fromMap(Map<String, dynamic> map) {
    return GadiVehicle(
      id: (map['id'] as num).toInt(),
      profileId: (map['profile_id'] as num).toInt(),
      name: map['name'] as String,
      vehicleType: GadiVehicleTypeExtension.fromString(map['vehicle_type'] as String? ?? 'car'),
      registrationNumber: map['registration_number'] as String,
      fuelType: GadiFuelTypeExtension.fromString(map['fuel_type'] as String? ?? 'petrol'),
      initialOdometer: (map['initial_odometer'] as num?)?.toDouble() ?? 0.0,
      currentOdometer: (map['current_odometer'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: map['purchase_date'] != null && (map['purchase_date'] as String).isNotEmpty
          ? parseDateOnly(map['purchase_date'])
          : null,
      purchasePrice: (map['purchase_price'] as num?)?.toDouble(),
      downPayment: (map['down_payment'] as num?)?.toDouble(),
      defaultReimbursementRate: (map['default_reimbursement_rate'] as num?)?.toDouble() ?? 0.0,
      chassisNumber: map['chassis_number'] as String?,
      engineNumber: map['engine_number'] as String?,
      insurancePolicyNumber: map['insurance_policy_number'] as String?,
      insuranceExpiryDate: map['insurance_expiry_date'] != null && (map['insurance_expiry_date'] as String).isNotEmpty
          ? parseDateOnly(map['insurance_expiry_date'])
          : null,
      pucExpiryDate: map['puc_expiry_date'] != null && (map['puc_expiry_date'] as String).isNotEmpty
          ? parseDateOnly(map['puc_expiry_date'])
          : null,
      fitnessExpiryDate: map['fitness_expiry_date'] != null && (map['fitness_expiry_date'] as String).isNotEmpty
          ? parseDateOnly(map['fitness_expiry_date'])
          : null,
      roadTaxExpiryDate: map['road_tax_expiry_date'] != null && (map['road_tax_expiry_date'] as String).isNotEmpty
          ? parseDateOnly(map['road_tax_expiry_date'])
          : null,
      serviceDueDate: map['service_due_date'] != null && (map['service_due_date'] as String).isNotEmpty
          ? parseDateOnly(map['service_due_date'])
          : null,
      serviceDueKm: (map['service_due_km'] as num?)?.toDouble(),
      serviceIntervalKm: (map['service_interval_km'] as num?)?.toDouble(),
      serviceIntervalMonths: (map['service_interval_months'] as num?)?.toInt(),
      isActive: (map['is_active'] as num?)?.toInt() == 1,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  GadiVehicle copyWith({
    String? name,
    GadiVehicleType? vehicleType,
    String? registrationNumber,
    GadiFuelType? fuelType,
    double? initialOdometer,
    double? currentOdometer,
    DateTime? purchaseDate,
    double? purchasePrice,
    double? downPayment,
    double? defaultReimbursementRate,
    String? chassisNumber,
    String? engineNumber,
    String? insurancePolicyNumber,
    DateTime? insuranceExpiryDate,
    DateTime? pucExpiryDate,
    DateTime? fitnessExpiryDate,
    DateTime? roadTaxExpiryDate,
    DateTime? serviceDueDate,
    double? serviceDueKm,
    double? serviceIntervalKm,
    int? serviceIntervalMonths,
    bool? isActive,
    String? notes,
  }) {
    return GadiVehicle(
      id: id,
      profileId: profileId,
      name: name ?? this.name,
      vehicleType: vehicleType ?? this.vehicleType,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      fuelType: fuelType ?? this.fuelType,
      initialOdometer: initialOdometer ?? this.initialOdometer,
      currentOdometer: currentOdometer ?? this.currentOdometer,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      downPayment: downPayment ?? this.downPayment,
      defaultReimbursementRate: defaultReimbursementRate ?? this.defaultReimbursementRate,
      chassisNumber: chassisNumber ?? this.chassisNumber,
      engineNumber: engineNumber ?? this.engineNumber,
      insurancePolicyNumber: insurancePolicyNumber ?? this.insurancePolicyNumber,
      insuranceExpiryDate: insuranceExpiryDate ?? this.insuranceExpiryDate,
      pucExpiryDate: pucExpiryDate ?? this.pucExpiryDate,
      fitnessExpiryDate: fitnessExpiryDate ?? this.fitnessExpiryDate,
      roadTaxExpiryDate: roadTaxExpiryDate ?? this.roadTaxExpiryDate,
      serviceDueDate: serviceDueDate ?? this.serviceDueDate,
      serviceDueKm: serviceDueKm ?? this.serviceDueKm,
      serviceIntervalKm: serviceIntervalKm ?? this.serviceIntervalKm,
      serviceIntervalMonths: serviceIntervalMonths ?? this.serviceIntervalMonths,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class GadiEvidence {
  final int id;
  final int eventId;
  final String filePath;
  final String originalName;
  final String displayName;
  final String mimeType;
  final String evidenceType;
  final DateTime createdAt;

  const GadiEvidence({
    required this.id,
    required this.eventId,
    required this.filePath,
    required this.originalName,
    required this.displayName,
    required this.mimeType,
    required this.evidenceType,
    required this.createdAt,
  });

  bool get isPdf => mimeType.contains('pdf') || filePath.toLowerCase().endsWith('.pdf');
  bool get isImage => !isPdf;

  Map<String, dynamic> toMap() => {
    if (id > 0) 'id': id,
    'event_id': eventId,
    'file_path': filePath,
    'original_name': originalName,
    'display_name': displayName,
    'mime_type': mimeType,
    'evidence_type': evidenceType,
    'created_at': createdAt.toIso8601String(),
  };

  factory GadiEvidence.fromMap(Map<String, dynamic> map) {
    return GadiEvidence(
      id: (map['id'] as num).toInt(),
      eventId: (map['event_id'] as num).toInt(),
      filePath: map['file_path'] as String,
      originalName: map['original_name'] as String,
      displayName: map['display_name'] as String,
      mimeType: map['mime_type'] as String,
      evidenceType: map['evidence_type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class GadiEvent {
  final int id;
  final int profileId;
  final int vehicleId;
  final GadiEventType eventType;
  final String title;
  final DateTime eventDate;
  final String eventTime;
  final double? odometerKm;
  final double amount;
  final int? linkedTransactionId;
  final String sourceType;
  final String evidenceStatus;
  final String? payloadJson;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<GadiEvidence> evidence;

  const GadiEvent({
    required this.id,
    required this.profileId,
    required this.vehicleId,
    required this.eventType,
    required this.title,
    required this.eventDate,
    required this.eventTime,
    this.odometerKm,
    this.amount = 0.0,
    this.linkedTransactionId,
    this.sourceType = 'MANUAL',
    this.evidenceStatus = 'NONE',
    this.payloadJson,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.evidence = const [],
  });

  bool get hasEvidence => evidence.isNotEmpty || evidenceStatus == 'ATTACHED';

  FuelPayload? get fuelPayload {
    if (payloadJson == null || payloadJson!.isEmpty) return null;
    try {
      return FuelPayload.fromMap(jsonDecode(payloadJson!) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  ServicePayload? get servicePayload {
    if (payloadJson == null || payloadJson!.isEmpty) return null;
    try {
      return ServicePayload.fromMap(jsonDecode(payloadJson!) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  RepairPayload? get repairPayload {
    if (payloadJson == null || payloadJson!.isEmpty) return null;
    try {
      return RepairPayload.fromMap(jsonDecode(payloadJson!) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  EmiPayload? get emiPayload {
    if (payloadJson == null || payloadJson!.isEmpty) return null;
    try {
      return EmiPayload.fromMap(jsonDecode(payloadJson!) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  AccidentClaimPayload? get claimPayload {
    if (payloadJson == null || payloadJson!.isEmpty) return null;
    try {
      return AccidentClaimPayload.fromMap(jsonDecode(payloadJson!) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  ChallanPayload? get challanPayload {
    if (payloadJson == null || payloadJson!.isEmpty) return null;
    try {
      return ChallanPayload.fromMap(jsonDecode(payloadJson!) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() => {
    if (id > 0) 'id': id,
    'profile_id': profileId,
    'vehicle_id': vehicleId,
    'event_type': eventType.name,
    'title': title,
    'event_date': formatDateOnly(eventDate),
    'event_time': eventTime,
    'odometer_km': odometerKm,
    'amount': amount,
    'linked_transaction_id': linkedTransactionId,
    'source_type': sourceType,
    'evidence_status': evidenceStatus,
    'payload_json': payloadJson,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory GadiEvent.fromMap(Map<String, dynamic> map, {List<GadiEvidence> evidence = const []}) {
    return GadiEvent(
      id: (map['id'] as num).toInt(),
      profileId: (map['profile_id'] as num).toInt(),
      vehicleId: (map['vehicle_id'] as num).toInt(),
      eventType: GadiEventTypeExtension.fromString(map['event_type'] as String? ?? 'other'),
      title: map['title'] as String,
      eventDate: parseDateOnly(map['event_date']),
      eventTime: map['event_time'] as String? ?? '12:00',
      odometerKm: (map['odometer_km'] as num?)?.toDouble(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      linkedTransactionId: (map['linked_transaction_id'] as num?)?.toInt(),
      sourceType: map['source_type'] as String? ?? 'MANUAL',
      evidenceStatus: map['evidence_status'] as String? ?? 'NONE',
      payloadJson: map['payload_json'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      evidence: evidence,
    );
  }
}

class GadiTrip {
  final int id;
  final int profileId;
  final int vehicleId;
  final GadiTripType tripType;
  final DateTime startDateTime;
  final DateTime? endDateTime;
  final double startOdometer;
  final double endOdometer;
  final double distanceKm;
  final String? startLocation;
  final String? endLocation;
  final String? purpose;
  final double? reimbursementRatePerKm;
  final double? reimbursementAmount;
  final bool isReimbursed;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GadiTrip({
    required this.id,
    required this.profileId,
    required this.vehicleId,
    required this.tripType,
    required this.startDateTime,
    this.endDateTime,
    required this.startOdometer,
    required this.endOdometer,
    required this.distanceKm,
    this.startLocation,
    this.endLocation,
    this.purpose,
    this.reimbursementRatePerKm,
    this.reimbursementAmount,
    this.isReimbursed = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isBusiness => tripType.isBusinessTrip;

  double get computedReimbursement {
    if (reimbursementAmount != null && reimbursementAmount! > 0) {
      return reimbursementAmount!;
    }
    if (reimbursementRatePerKm != null && reimbursementRatePerKm! > 0) {
      return distanceKm * reimbursementRatePerKm!;
    }
    return 0.0;
  }

  Map<String, dynamic> toMap() => {
    if (id > 0) 'id': id,
    'profile_id': profileId,
    'vehicle_id': vehicleId,
    'trip_type': tripType.name,
    'start_date_time': startDateTime.toIso8601String(),
    'end_date_time': endDateTime?.toIso8601String(),
    'start_odometer': startOdometer,
    'end_odometer': endOdometer,
    'distance_km': distanceKm,
    'start_location': startLocation,
    'end_location': endLocation,
    'purpose': purpose,
    'reimbursement_rate_per_km': reimbursementRatePerKm,
    'reimbursement_amount': reimbursementAmount ?? computedReimbursement,
    'is_reimbursed': isReimbursed ? 1 : 0,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory GadiTrip.fromMap(Map<String, dynamic> map) {
    final startOdo = (map['start_odometer'] as num).toDouble();
    final endOdo = (map['end_odometer'] as num).toDouble();
    final rawDistance = (map['distance_km'] as num?)?.toDouble();
    final distance = rawDistance ?? (endOdo - startOdo > 0 ? endOdo - startOdo : 0.0);

    return GadiTrip(
      id: (map['id'] as num).toInt(),
      profileId: (map['profile_id'] as num).toInt(),
      vehicleId: (map['vehicle_id'] as num).toInt(),
      tripType: GadiTripTypeExtension.fromString(map['trip_type'] as String? ?? 'personal'),
      startDateTime: DateTime.parse(map['start_date_time'] as String),
      endDateTime: map['end_date_time'] != null && (map['end_date_time'] as String).isNotEmpty
          ? DateTime.parse(map['end_date_time'] as String)
          : null,
      startOdometer: startOdo,
      endOdometer: endOdo,
      distanceKm: distance,
      startLocation: map['start_location'] as String?,
      endLocation: map['end_location'] as String?,
      purpose: map['purpose'] as String?,
      reimbursementRatePerKm: (map['reimbursement_rate_per_km'] as num?)?.toDouble(),
      reimbursementAmount: (map['reimbursement_amount'] as num?)?.toDouble(),
      isReimbursed: (map['is_reimbursed'] as num?)?.toInt() == 1,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class GadiDue {
  final int id;
  final int profileId;
  final int vehicleId;
  final GadiDueType dueType;
  final String title;
  final DateTime? dueDate;
  final double? dueKm;
  final double? amount;
  final GadiDueStatus status;
  final DateTime? snoozedUntil;
  final int? resolvedEventId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GadiDue({
    required this.id,
    required this.profileId,
    required this.vehicleId,
    required this.dueType,
    required this.title,
    this.dueDate,
    this.dueKm,
    this.amount,
    this.status = GadiDueStatus.pending,
    this.snoozedUntil,
    this.resolvedEventId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isResolved => status == GadiDueStatus.completed;

  bool isOverdue(double? currentVehicleOdometer) {
    if (isResolved) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (dueDate != null) {
      final target = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
      if (target.isBefore(today)) return true;
    }
    if (dueKm != null && currentVehicleOdometer != null) {
      if (currentVehicleOdometer >= dueKm!) return true;
    }
    return false;
  }

  bool isDueSoon({required int daysThreshold, double? currentVehicleOdometer, double kmThreshold = 250}) {
    if (isResolved || isOverdue(currentVehicleOdometer)) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (dueDate != null) {
      final target = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
      final daysDiff = target.difference(today).inDays;
      if (daysDiff >= 0 && daysDiff <= daysThreshold) return true;
    }
    if (dueKm != null && currentVehicleOdometer != null) {
      final kmDiff = dueKm! - currentVehicleOdometer;
      if (kmDiff >= 0 && kmDiff <= kmThreshold) return true;
    }
    return false;
  }

  Map<String, dynamic> toMap() => {
    if (id > 0) 'id': id,
    'profile_id': profileId,
    'vehicle_id': vehicleId,
    'due_type': dueType.name,
    'title': title,
    'due_date': dueDate != null ? formatDateOnly(dueDate!) : null,
    'due_km': dueKm,
    'amount': amount,
    'status': status.name.toUpperCase(),
    'snoozed_until': snoozedUntil?.toIso8601String(),
    'resolved_event_id': resolvedEventId,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory GadiDue.fromMap(Map<String, dynamic> map) {
    final statusStr = (map['status'] as String? ?? 'PENDING').toLowerCase();
    GadiDueStatus resolvedStatus = GadiDueStatus.pending;
    if (statusStr.contains('overdue')) {
      resolvedStatus = GadiDueStatus.overdue;
    } else if (statusStr.contains('completed') || statusStr.contains('resolved')) {
      resolvedStatus = GadiDueStatus.completed;
    } else if (statusStr.contains('snoozed')) {
      resolvedStatus = GadiDueStatus.snoozed;
    }

    return GadiDue(
      id: (map['id'] as num).toInt(),
      profileId: (map['profile_id'] as num).toInt(),
      vehicleId: (map['vehicle_id'] as num).toInt(),
      dueType: GadiDueTypeExtension.fromString(map['due_type'] as String? ?? 'puc'),
      title: map['title'] as String,
      dueDate: map['due_date'] != null && (map['due_date'] as String).isNotEmpty
          ? parseDateOnly(map['due_date'])
          : null,
      dueKm: (map['due_km'] as num?)?.toDouble(),
      amount: (map['amount'] as num?)?.toDouble(),
      status: resolvedStatus,
      snoozedUntil: map['snoozed_until'] != null && (map['snoozed_until'] as String).isNotEmpty
          ? DateTime.parse(map['snoozed_until'] as String)
          : null,
      resolvedEventId: (map['resolved_event_id'] as num?)?.toInt(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class GadiOdometerLog {
  final int id;
  final int vehicleId;
  final double odometerKm;
  final String recordedDate;
  final String recordedTime;
  final String sourceType; // EVENT, TRIP, CALIBRATION
  final int? sourceId;
  final bool isManualCalibration;
  final String? calibrationReason;
  final DateTime createdAt;

  const GadiOdometerLog({
    required this.id,
    required this.vehicleId,
    required this.odometerKm,
    required this.recordedDate,
    required this.recordedTime,
    this.sourceType = 'EVENT',
    this.sourceId,
    this.isManualCalibration = false,
    this.calibrationReason,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id > 0) 'id': id,
    'vehicle_id': vehicleId,
    'odometer_km': odometerKm,
    'recorded_date': recordedDate,
    'recorded_time': recordedTime,
    'source_type': sourceType,
    'source_id': sourceId,
    'is_manual_calibration': isManualCalibration ? 1 : 0,
    'calibration_reason': calibrationReason,
    'created_at': createdAt.toIso8601String(),
  };

  factory GadiOdometerLog.fromMap(Map<String, dynamic> map) {
    return GadiOdometerLog(
      id: (map['id'] as num).toInt(),
      vehicleId: (map['vehicle_id'] as num).toInt(),
      odometerKm: (map['odometer_km'] as num).toDouble(),
      recordedDate: map['recorded_date'] as String,
      recordedTime: map['recorded_time'] as String,
      sourceType: map['source_type'] as String? ?? 'EVENT',
      sourceId: (map['source_id'] as num?)?.toInt(),
      isManualCalibration: (map['is_manual_calibration'] as num?)?.toInt() == 1,
      calibrationReason: map['calibration_reason'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class InspectionItem {
  final String name;
  final String marathiName;
  final bool passed;
  final String? note;

  const InspectionItem({
    required this.name,
    required this.marathiName,
    required this.passed,
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'marathi_name': marathiName,
    'passed': passed,
    'note': note,
  };

  factory InspectionItem.fromMap(Map<String, dynamic> map) {
    return InspectionItem(
      name: map['name'] as String,
      marathiName: map['marathi_name'] as String? ?? '',
      passed: map['passed'] as bool? ?? true,
      note: map['note'] as String?,
    );
  }
}

class GadiInspectionLog {
  final int id;
  final int vehicleId;
  final DateTime inspectionDate;
  final double? odometerKm;
  final List<InspectionItem> items;
  final String overallStatus; // ALL_GOOD, ATTENTION_NEEDED
  final String? notes;
  final DateTime createdAt;

  const GadiInspectionLog({
    required this.id,
    required this.vehicleId,
    required this.inspectionDate,
    this.odometerKm,
    required this.items,
    this.overallStatus = 'ALL_GOOD',
    this.notes,
    required this.createdAt,
  });

  bool get isAllGood => overallStatus == 'ALL_GOOD';

  Map<String, dynamic> toMap() => {
    if (id > 0) 'id': id,
    'vehicle_id': vehicleId,
    'inspection_date': inspectionDate.toIso8601String(),
    'odometer_km': odometerKm,
    'items_json': jsonEncode(items.map((e) => e.toMap()).toList()),
    'overall_status': overallStatus,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
  };

  factory GadiInspectionLog.fromMap(Map<String, dynamic> map) {
    List<InspectionItem> itemsList = [];
    if (map['items_json'] != null && (map['items_json'] as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(map['items_json'] as String) as List<dynamic>;
        itemsList = decoded.map((e) => InspectionItem.fromMap(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    return GadiInspectionLog(
      id: (map['id'] as num).toInt(),
      vehicleId: (map['vehicle_id'] as num).toInt(),
      inspectionDate: DateTime.parse(map['inspection_date'] as String),
      odometerKm: (map['odometer_km'] as num?)?.toDouble(),
      items: itemsList,
      overallStatus: map['overall_status'] as String? ?? 'ALL_GOOD',
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
