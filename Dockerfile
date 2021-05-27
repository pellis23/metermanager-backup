# Define function directory
ARG FUNCTION_DIR="/function"

FROM python:buster as build-image

# Install dependencies
ENV TZ=Europe/London
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install aws-lambda-cpp build dependencies
RUN apt-get update && apt-get install -y g++ make cmake unzip libcurl4-openssl-dev

# Include global arg in this stage of the build
ARG FUNCTION_DIR
# Create function directory
RUN mkdir -p ${FUNCTION_DIR}
# Copy function code
COPY app.py ${FUNCTION_DIR}
RUN chmod 555 ${FUNCTION_DIR}/app.py

# Install the runtime interface client
RUN pip install --target ${FUNCTION_DIR} awslambdaric

# Multi-stage build: grab a fresh copy of the base image
FROM python:buster

# Include global arg in this stage of the build
ARG FUNCTION_DIR
# Set working directory to function root directory
WORKDIR ${FUNCTION_DIR}

# Copy in the build image dependencies
COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}

# install awscli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

RUN mkdir /script
ADD script.py /script/script.py
RUN chmod 555 /script/script.py
ADD script.sh /script/script.sh
RUN chmod 555 /script/script.sh

ENTRYPOINT [ "/script/script.py" ]
CMD ["app.handler"]
