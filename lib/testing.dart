/// Testing support for implementations of the Foundations contracts.
///
/// Provides the inter-module communication conformance check that Core and
/// standalone stubs run in their own test suites. It depends on no test
/// framework, and it is never needed in production code.
library;

export 'src/testing/inter_module_conformance.dart';
