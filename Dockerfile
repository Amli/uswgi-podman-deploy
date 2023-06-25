FROM debian:buster-20230612-slim
ARG VERSION

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y -qq && \
    apt-get install --no-install-recommends -y -qq uwsgi uwsgi-plugin-python3 python3 python3-venv
ENV DEBIAN_FRONTEND=
RUN python3 -m venv /opt/venv
COPY app.py /opt/
COPY uwsgi-zergling.ini /opt/uwsgi.ini

WORKDIR /opt/
ENV VERSION=$VERSION
ENTRYPOINT ["uwsgi", "--ini", "/opt/uwsgi.ini"]
