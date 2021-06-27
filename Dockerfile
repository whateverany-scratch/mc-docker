ARG REPOSITORY_URL
ARG SOURCE_VERSION
ARG SOURCE_APP_NAME

FROM ${REPOSITORY_URL}/${SOURCE_APP_NAME}:${SOURCE_VERSION}

#USER root
#COPY src/rootfs/ /
#
#ARG JFROG_URL
#
#RUN set -x ;\
#    echo "INFO: BEGIN run." ;\
#    sed -i.orig -e "1s/^/openssl_conf = default_conf\n/" \
#      -e "$ a [default_conf]\nssl_conf = ssl_sect\n\n[ssl_sect]\nsystem_default = ssl_default_sect\n\n[ssl_default_sect]\nCipherString = DEFAULT:@SECLEVEL=1\n" \
#      /etc/ssl/openssl.cnf ;\
#    update-ca-certificates --verbose ;\
#    echo "INFO: JFROG_URL=${JFROG_URL}" ;\
#    echo "deb [trusted=yes] ${JFROG_URL}/deb/ focal main restricted" > /etc/apt/sources.list ;\
#    echo "deb [trusted=yes] ${JFROG_URL}/deb/ focal-updates main restricted" >> /etc/apt/sources.list ;\
#    apt-get update ;\
#    apt-get install -y --no-install-recommends \
#      apt-utils=2.0.5 \
#      busybox-static=1:1.30.1-4ubuntu6.3 \
#      make=4.2.1-1.2 \
#      ;\
#    busybox --install ;\
#    rm -rf /var/lib/apt/lists/* ;\
#    apt-get autoremove -y ;\
#    mkdir -p "/home/default" ;\
#    chown -R default:root "/home/default" ;\
#    echo "INFO: END update and add packages"
#
#USER default
#
## Pre copy steps to setup liberty
#RUN set -x ;\
#    echo "INFO: BEGIN RUN..." ;\
#    echo "INFO: Update featureUtility.properties to use ${JFROG_URL}" ;\
#    mkdir /opt/ol/wlp/etc ;\
#    echo "remoteRepo.url=${JFROG_URL}/all" >> /opt/ol/wlp/etc/featureUtility.properties ;\
#    echo "INFO: Install features (see https://openliberty.io/docs/21.0.0.5/reference/feature/feature-overview.html)" ;\
#    featureUtility installFeature \
#      appSecurity-3.0 \
#      jca-1.7 \
#      jndi-1.0 \
#      jsf-2.3 \
#      jsfContainer-2.3 \
#      jsp-2.3 \
#      wasJmsClient-2.0 \
#    ;\
#    # Unused features, uncomment and move above to enable. \
#    echo "INFO: Run liberty container configure script" ;\
#    VERBOSE=true configure.sh ;\
#    echo "INFO: END RUN"
