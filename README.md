# text-rdt

## Setup
```bash
nix shell nixpkgs#sbt nixpkgs#openjdk21 nixpkgs#nodejs
codium .

testOnly text_rdt.OTAlgorithmTestSuite -- text_rdt.OTAlgorithmTestSuite.regression-13

cd text-rdt
nix develop .#text-rdt-sbt-tests-thesis
#npm install
npm run build -- --base=./ # TODO split this up
npm run preview

cd text-rdt
nix develop .#text-rdt-sbt-tests-thesis
sbt "testOnly text_rdt.ComplexAVLBrowserFugueScalaCheckSuite"
```

## COTURN for demo

```
sudo docker run -d --network=host docker.io/coturn/coturn --verbose --lt-cred-mech --user moritz:password --realm text-rdt
```

## Troubleshooting

Delete caches

```bash
rm -R ~/.ivy2/ ~/.cache/scalablytyped/
```

## IDE

### IntelliJ

To fix import errors in the tests of the shared module, go to Module Settings -> Dependencies -> Add -> Module Dependency and add the JVM module.

## Updating

```bash
sbt dependencyUpdates
```

## Testing

```bash
sbt
textrdtJVM/testOnly -- --exclude-tags=browser
textrdtJVM/testOnly -- --exclude-tags=browser,scalacheck

textrdtJVM/testQuick -- --exclude-tags=browser

testOnly -- -F
```

## Coverage

```bash
npm run build && npm run preview
sbt clean coverage textrdtJVM/test coverageReport
```

## Development

```bash
npm run dev
sbt ~fastLinkJS # always keep this in background so tests have up-to-date code
```
