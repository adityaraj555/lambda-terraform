from typing import Any, Optional

from common_utils.error_utils import ErrorBody


class LambdaException(Exception):
    """Generic Error to indicate any failure in Lambda Execution
    Args:
        message (str): Error message
        error_code (Optional[int], optional): Error code returned
    """

    def __init__(
        self,
        message: str,
        error_code: Optional[int],
        server_error_code: Optional[int],
        details: Optional[str] = None,
        **kwargs: Any,
    ):
        self.error_code = error_code
        self.server_error_code = server_error_code
        self.message = f"ServiceException, error_code: {self.error_code}, \
            error_message: {message}"
        self.details = details
        for k, v in kwargs.items():
            setattr(self, k, v)
        super().__init__(message)


def handle_exception(
    raise_error: ErrorBody,
    details: Optional[str] = None,
    service: Optional[str] = None,
    server_error_code: Optional[int] = None,
    **kwargs
) -> None:
    """raises a client exception depending on on server returned status"""

    raise LambdaException(
        error_code=raise_error.code,
        message=raise_error.message,
        details=details,
        server_error_code=server_error_code
    )
