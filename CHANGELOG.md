## 0.5.0
* Add support for multipart/form-data file uploads with JSON content FormParts

## 0.4.4
* Ensure Zlib::GzipReader/Writer is used for inflating/deflating gzippable HTTP request bodies.

## 0.4.3
* Fix bug where nested array responses were not completely deserialized into openstructs.

## 0.4.2
* Fix bug where nested responses were not completely deserialized into openstructs.

## 0.4.1
* Fix regression where boundary parameter was not set in multipart requests.

## 0.4.0
* Add gzip support.
* Ensure requests are immutable.

## 0.3.0
* Add Form encoder.

## 0.2.0
* Remove serialize/deserialize methods in http client in favor of exposing encoder.
* Move multipart serialization into separate encoder.

## 0.1.5
* Use releasinator to automate releases.
* Fix releasinator script.

## 0.1.4
* Use releasinator to automate releases.

## 0.1.3
* Support JSON array response data.
