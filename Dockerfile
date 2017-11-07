FROM openjdk:8

ENV DEBIAN_FRONTEND noninteractive

# Install dependencies
RUN apt-get -qq update && \
    apt-get -qqy install --no-install-recommends \
       unzip tree \
     && rm -rf /var/lib/apt/lists/*

# Everything will be installed in the directory but jdk.
ENV SDK_HOME /usr/local

# Download and unzip Gradle
ENV GRADLE_VERSION 3.3
ENV GRADLE_SDK_URL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip
RUN curl -sSL "${GRADLE_SDK_URL}" -o gradle-${GRADLE_VERSION}-bin.zip  \
	&& unzip gradle-${GRADLE_VERSION}-bin.zip -d ${SDK_HOME}  \
	&& rm -rf gradle-${GRADLE_VERSION}-bin.zip
ENV GRADLE_HOME ${SDK_HOME}/gradle-${GRADLE_VERSION}
ENV PATH ${GRADLE_HOME}/bin:$PATH

# Install dependencies
RUN dpkg --add-architecture i386 && \
    apt-get -qq update && \
    apt-get -qqy install libc6:i386 libstdc++6:i386 zlib1g:i386 libncurses5:i386 unzip tar git --no-install-recommends && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/*

# Download and unzip Android SDK
ENV ANDROID_HOME ${SDK_HOME}/android-sdk-linux
ENV ANDROID_SDK ${SDK_HOME}/android-sdk-linux
ENV ANDROID_SDK_MANAGER ${SDK_HOME}/android-sdk-linux/tools/bin/sdkmanager

ENV ANDROID_SDK_VERSION r25.2.3
ENV ANDROID_SDK_URL https://dl.google.com/android/repository/tools_${ANDROID_SDK_VERSION}-linux.zip
RUN curl -sSL "${ANDROID_SDK_URL}" -o tools_${ANDROID_SDK_VERSION}-linux.zip \
    && unzip tools_${ANDROID_SDK_VERSION}-linux.zip -d ${ANDROID_HOME} \
  && rm -rf tools_${ANDROID_SDK_VERSION}-linux.zip
  
# Install Android SDK Components
ENV ANDROID_COMPONENTS "tools" \
                       "platform-tools" \
                       "build-tools;26.0.2" \                                              
                       "platforms;android-26" 

ENV GOOGLE_COMPONENTS "extras;android;m2repository" \
                       "extras;google;m2repository" \
                       "extras;google;google_play_services"

ENV CONSTRAINT_LAYOUT "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2"\
                       "extras;m2repository;com;android;support;constraint;constraint-layout-solver;1.0.2"

RUN mkdir -p ${ANDROID_HOME}/licenses/ && \
    echo "8933bad161af4178b1185d1a37fbf41ea5269c55" > ${ANDROID_HOME}/licenses/android-sdk-license && \
    echo "84831b9409646a918e30573bab4c9c91346d8abd" > ${ANDROID_HOME}/licenses/android-sdk-preview-license && \
    ${ANDROID_SDK_MANAGER}  ${ANDROID_COMPONENTS} \
                            ${GOOGLE_COMPONENTS} \
                            ${CONSTRAINT_LAYOUT}  

ENV PATH ${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/26.0.2:$PATH

RUN apt-get update && apt-get install python-pip -y && pip install awscli

ENV NODE_VERSION 8.9.0

# set up node
RUN buildDeps='xz-utils gnupg2 dirmngr' \
    && set -x \
    && apt-get update && apt-get install -y $buildDeps --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    56730D5401028683275BD23C23EFEFE93C4CFFFE \
  ; do \
    gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
  done \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
    && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
    && apt-get purge -y --auto-remove $buildDeps \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs    
    
RUN npm i -g ionic cordova@6.5  
