import 'package:foundations/foundations.dart';

import 'reference_inter_module_communication.dart';

/// Calls the provider even when a required parameter is absent or null.
InterModuleCommunication ignoresRequiredParameters() =>
    ReferenceInterModuleCommunication.withDefects(
      const Defects(ignoreRequiredParameters: true),
    );

/// Lets handler and factory exceptions escape instead of returning 500.
InterModuleCommunication rethrowsHandlerErrors() =>
    ReferenceInterModuleCommunication.withDefects(
      const Defects(rethrowHandlerErrors: true),
    );

/// Exposes the exception text in the 500 response.
InterModuleCommunication leaksExceptionText() =>
    ReferenceInterModuleCommunication.withDefects(
      const Defects(leakExceptionText: true),
    );

/// Silently replaces an existing registration instead of throwing.
InterModuleCommunication acceptsDuplicates() =>
    ReferenceInterModuleCommunication.withDefects(
      const Defects(acceptDuplicates: true),
    );

/// Uses one registry for both endpoint types.
InterModuleCommunication sharesOneRegistry() =>
    ReferenceInterModuleCommunication.withDefects(
      const Defects(shareOneRegistry: true),
    );
