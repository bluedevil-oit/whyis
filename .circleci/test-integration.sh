#!/bin/bash

WHYIS_DEMO_IMAGE="${1:-tetherlessworld/whyis-demo:latest}"

mkdir -p test-results/js
echo "`date` Running integration tests in $WHYIS_DEMO_IMAGE"
JS_REDIRECT=""
docker run $WHYIS_DEMO_IMAGE bash -c "mkdir -p /apps/whyis/test-results/js && curl -sL https://deb.nodesource.com/setup_12.x | bash - $JS_REDIRECT && apt-get install -y nodejs xvfb libgtk-3-dev libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 $JS_REDIRECT && cd /apps/whyis/tests/integration && npm install $JS_REDIRECT && CYPRESS_baseUrl=http://localhost npm run cypress:run $JS_REDIRECT"
#JS_REDIRECT=">/apps/whyis/test-results/js/test.out 2>/apps/whyis/test-results/js/test.err"
#docker run $WHYIS_DEMO_IMAGE bash -c "mkdir -p /apps/whyis/test-results/js && curl -sL https://deb.nodesource.com/setup_12.x | bash - $JS_REDIRECT && apt-get install -y nodejs xvfb libgtk-3-dev libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 $JS_REDIRECT && cd /apps/whyis/tests/integration && npm install $JS_REDIRECT && CYPRESS_baseUrl=http://localhost npm run cypress:run-ci $JS_REDIRECT; cp -p -R cypress/screenshots /apps/whyis/test-results/js; cp -p -R cypress/videos /apps/whyis/test-results/js; cd /apps/whyis && tar cf test-results-js.tar test-results/js && cat test-results-js.tar" >test-results-js.tar
tar xf test-results-js.tar
echo "`date` Integration test stdout:"
cat test-results/js/test.out
echo "`date` Integration test stderr:"
cat test-results/js/test.err
if [ ! -f "test-results/js/results.xml" ]; then
    echo "Integration test results.xml does not exist, exiting abnormally"
    exit 1
fi
if [ "$(grep -c 'failure ' test-results/js/results.xml)" -ge 1 ]; then
    echo "Integration test results.xml has failures, exiting abnormally"
    exit 1
fi

echo "`date` Exiting normally"
exit 0
