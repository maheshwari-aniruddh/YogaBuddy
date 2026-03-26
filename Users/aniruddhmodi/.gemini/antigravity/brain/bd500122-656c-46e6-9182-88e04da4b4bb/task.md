# Fix dSYM Upload Errors

- [x] Check `ios/Podfile` for build settings
- [x] Configure `DEBUG_INFORMATION_FORMAT` to `dwarf-with-dsym`
- [/] Apply enhanced build settings (GCC_GENERATE_DEBUGGING_SYMBOLS, STRIP_INSTALLED_PRODUCT)
- [ ] Deep clean Pods cache and Rebuild IPA
- [ ] Verify dSYMs in Archive
