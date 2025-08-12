import 'package:modugo/modugo.dart';

/// Extension that provides a default [BindingKeyModel] for backward compatibility.
///
/// This extension allows any `Type` to easily generate its corresponding
/// default [BindingKeyModel] instance. The default key is created using
/// the type itself and an empty name, ensuring compatibility with
/// previous versions that did not require a custom key name.
extension BindingKeyExtensions on Type {
  /// Returns a default [BindingKeyModel] for this type.
  ///
  /// The generated key uses the current type and an empty name (`''`).
  BindingKeyModel get defaultKey => BindingKeyModel.fromType(this, '');
}
