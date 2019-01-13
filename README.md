# IPAUnsigner

## Description
IPAUnsigner is a simple bash script that hep you to unsign ipa files and install them on your device via Cydia Impactor for example.

## Requirements
* macOS (any version)
* Xcode or Xcode Command Line Toools. If you don't have any of these, you can install just CLT using command `xcode-select --install`


## Usage
`./ipaunsigner.sh path_to_ipa_file`

It will process ipa file and create simillar with appended *_unsigned* on the end of ipa name.

**For example,** entering command

`./ipaunsigner.sh /Users/daniil/vk.ipa`

will produce ipa file with name `vk_unsigned.ipa` and located in `/Users/daniil` directory.

## License
IPAUnsigner is available under the MIT licence. You can read full text in [LICENSE](./LICENSE)