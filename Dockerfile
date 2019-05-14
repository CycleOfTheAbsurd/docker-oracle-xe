FROM oraclelinux:7-slim
LABEL MAINTAINER="Adrian Png <adrian.png@fuzziebrain.com>"

ENV \
  # The only environment variable that should be changed!
  USER_PASSWORD=OracleUser \
  ORACLE_PASSWORD=Oracle18 \
  ORACLE_USER_PASSWORD=OracleUserPass18 \
  EM_GLOBAL_ACCESS_YN=Y \
  # DO NOT CHANGE 
  ORACLE_DOCKER_INSTALL=true \
  ORACLE_SID=XE \
  ORACLE_BASE=/opt/oracle \
  ORACLE_HOME=/opt/oracle/product/18c/dbhomeXE \
  ORAENV_ASK=NO \
  RUN_FILE=runOracle.sh \
  SHUTDOWN_FILE=shutdownDb.sh \
  EM_REMOTE_ACCESS=enableEmRemoteAccess.sh \
  EM_RESTORE=reconfigureEm.sh \
  CHECK_DB_FILE=checkDBStatus.sh

COPY ./files/ /tmp/

RUN yum install -y oracle-database-preinstall-18c openssl && \
  yum localinstall -y /tmp/oracle-database-xe-18c-*.rpm && \
  rm -rf /tmp/oracle-*

COPY ./scripts/*.sh ${ORACLE_BASE}/scripts/

RUN install -d -m 775 -g dba /usr/share/db
RUN chmod a+x ${ORACLE_BASE}/scripts/*.sh

RUN useradd -ms /bin/bash oracle_user -p "$(openssl passwd -1 $USER_PASSWORD)"
RUN echo "PATH=$PATH:$ORACLE_HOME/bin/" >> /home/oracle_user/.bashrc

# 1521: Oracle listener
# 5500: Oracle Enterprise Manager (EM) Express listener.
EXPOSE 1521 5500

VOLUME [ "${ORACLE_BASE}/oradata" ]

HEALTHCHECK --interval=1m --start-period=2m --retries=10 \
  CMD "$ORACLE_BASE/scripts/$CHECK_DB_FILE"

CMD exec ${ORACLE_BASE}/scripts/${RUN_FILE}