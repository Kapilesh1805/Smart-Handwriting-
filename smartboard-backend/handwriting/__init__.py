"""Handwriting analysis package.

Provides alphabet and number recognition pipelines.
"""

# Lazy imports - only load when explicitly imported to avoid circular dependencies
# This allows the package to be imported even if some modules have unresolved dependencies

__all__ = ['analyze_letter', 'analyze_number']

