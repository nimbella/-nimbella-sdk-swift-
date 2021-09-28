#
# Copyright (c) 2021 - present Joshua Auerbach
#
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.
#

# This Dockerfile is used by buildImage.sh.  See comments there.

FROM action-swift-v5.4
RUN mkdir /root/.nimbella /root/redis-lite /root/storage-lite
COPY credentials.json /root/.nimbella
COPY swift-sdk-tests.env /root/.nimbella
COPY redis-lite /root/redis-lite
COPY storage-lite /root/storage-lite
COPY redis-exec /root/redis-exec
COPY storage-exec /root/storage-exec


