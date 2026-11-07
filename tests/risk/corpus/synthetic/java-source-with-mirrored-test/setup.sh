#!/usr/bin/env bash
set -eu
printf '# Demo\n' > README.md
mkdir -p svc/src/main/java/com/acme svc/src/test/java/com/acme
printf '<project/>\n' > svc/pom.xml
printf 'class Order {}\n' > svc/src/main/java/com/acme/Order.java
printf 'class OrderTest {}\n' > svc/src/test/java/com/acme/OrderTest.java
