// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payout_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(payoutsByRole)
const payoutsByRoleProvider = PayoutsByRoleFamily._();

final class PayoutsByRoleProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PayoutModel>>,
          List<PayoutModel>,
          Stream<List<PayoutModel>>
        >
    with
        $FutureModifier<List<PayoutModel>>,
        $StreamProvider<List<PayoutModel>> {
  const PayoutsByRoleProvider._({
    required PayoutsByRoleFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'payoutsByRoleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$payoutsByRoleHash();

  @override
  String toString() {
    return r'payoutsByRoleProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<PayoutModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PayoutModel>> create(Ref ref) {
    final argument = this.argument as String;
    return payoutsByRole(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PayoutsByRoleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$payoutsByRoleHash() => r'0795a291292fb7f97e013a51ee66f3f63976820f';

final class PayoutsByRoleFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<PayoutModel>>, String> {
  const PayoutsByRoleFamily._()
    : super(
        retry: null,
        name: r'payoutsByRoleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PayoutsByRoleProvider call(String role) =>
      PayoutsByRoleProvider._(argument: role, from: this);

  @override
  String toString() => r'payoutsByRoleProvider';
}

@ProviderFor(payoutsByUser)
const payoutsByUserProvider = PayoutsByUserFamily._();

final class PayoutsByUserProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PayoutModel>>,
          List<PayoutModel>,
          Stream<List<PayoutModel>>
        >
    with
        $FutureModifier<List<PayoutModel>>,
        $StreamProvider<List<PayoutModel>> {
  const PayoutsByUserProvider._({
    required PayoutsByUserFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'payoutsByUserProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$payoutsByUserHash();

  @override
  String toString() {
    return r'payoutsByUserProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<PayoutModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PayoutModel>> create(Ref ref) {
    final argument = this.argument as String;
    return payoutsByUser(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PayoutsByUserProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$payoutsByUserHash() => r'ee304f9daaf27b5d58545b0fb2d8ccd98eafdc9d';

final class PayoutsByUserFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<PayoutModel>>, String> {
  const PayoutsByUserFamily._()
    : super(
        retry: null,
        name: r'payoutsByUserProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PayoutsByUserProvider call(String userId) =>
      PayoutsByUserProvider._(argument: userId, from: this);

  @override
  String toString() => r'payoutsByUserProvider';
}
