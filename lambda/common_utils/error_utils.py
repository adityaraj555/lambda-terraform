"""
__author__: EVML
contact: ml-evin@eagleview.com
Created: September 2022
Copyright 2021 , EagleView
"""

from enum import Enum
from typing import NamedTuple


class ErrorBody(NamedTuple):
    code: int
    message: str


class ErrorCatalog(ErrorBody, Enum):

    # Common Errors across Lambdas
    RequiredKeyNotInInput = ErrorBody(code=9001, message="Required key not present in Input")
    CouldNotConnectToAWS = ErrorBody(code=9004, message="Client could not connect to AWS")

    NoMetadataPresent = ErrorBody(
        code=9023, message="No metadata information from metas or metas_file_paths"
    )
