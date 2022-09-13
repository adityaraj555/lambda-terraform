ARG BASE_IMAGE=python:3.9-slim
FROM $BASE_IMAGE as build-image

ENV POETRY_VERSION=1.1.13

ARG ARTIFACTORY_USERNAME
ARG ARTIFACTORY_PASSWORD
ARG FUNCTION_NAME

COPY lambda/${FUNCTION_NAME}/* /evml/
COPY lambda/common_utils/* /evml/common_utils/
ADD https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie /usr/bin/aws-lambda-rie

WORKDIR /evml
COPY scripts/entry.sh /

# Install the runtime interface client
RUN pip3 install --target /evml/ awslambdaric \
    && pip install "poetry==$POETRY_VERSION" \
    && poetry config http-basic.ev ${ARTIFACTORY_USERNAME} ${ARTIFACTORY_PASSWORD} \
    && poetry config virtualenvs.create false \
    && poetry install --no-interaction --no-ansi \
    && chmod 755 /usr/bin/aws-lambda-rie /entry.sh

ENTRYPOINT [ "/entry.sh" ]

CMD [ "handler.lambda_handler" ]