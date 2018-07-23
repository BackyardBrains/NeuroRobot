"""Google Cloud namespace package."""

# GOOGLE_INTERNAL_BEGIN
# pylint: disable=g-import-not-at-top
__path__.append(__path__[0] + '/core_future')
try:
  future = __import__(__name__ + '.core_future')
except ImportError as e:
  future_import_error = e
else:
  future_import_error = None

try:
# GOOGLE_INTERNAL_END

  try:
      import pkg_resources
      pkg_resources.declare_namespace(__name__)
  except ImportError:
      import pkgutil
      __path__ = pkgutil.extend_path(__path__, __name__)


# GOOGLE_INTERNAL_BEGIN
except ImportError as e:
  if future_import_error:
    raise
else:
  if not future_import_error:
    raise RuntimeError('Conflicting versions of core found: {:core, :core_future}')
# GOOGLE_INTERNAL_END
