# Thesis

Contains notes and testing for my thesis paper.

Setup repo for analysis.
branched from Herbie main `9e2e21f`
```sh
git clone git@github.com:zaneenders/herbie.git
```

run nightlies, make install because of merging with commit issues.
```sh
chmod +x infra/nightly.sh
git checkout "old-algorithm"
make install
./infra/nightly.sh old-nightly 
git checkout "new-algorithm"
make install
./infra/nightly.sh new-nightly 
```

Running local server to view nightly.
```sh
python3 -m http.server 42069
```

# Thesis
/old-nightly
/new-nightly