# Language List
A list of languages based upon ISO-639-1 and ISO-639-3 with functions to retrieve only common languages.

[![Build Status](https://travis-ci.org/scsmith/language_list.svg?branch=master)](https://travis-ci.org/scsmith/language_list)

## Examples
    # Get an array of LanguageList::LanguageInfo classes
    all_languages = LanguageList::ALL_LANGUAGES
    common_languages = LanguageList::COMMON_LANGUAGES

    # Finding a language based on its ISO-639-1 or ISO-639-3 code or
    # name
    german  = LanguageList::LanguageInfo.find('German')
    english = LanguageList::LanguageInfo.find('en')
    english.name.inspect #=> "English"
    english.iso_639_1.inspect #=> "en"
    english.iso_639_3.inspect #=> "eng"
    english.common? #=> true

## Testing

    rake

## Upgrading

### 1.1 to 1.2

  * Version 1.2 freezes all of the constants once they're loaded.

## Thanks
Thanks goes to Steve Hardie for his work on creating a list of common languages (http://stevehardie.com/2009/10/list-of-common-languages/).

## License
I don't actually know the license for this project. The project contains countries from the ISO language list although they were not obtained from the ISO website. The country list has been adapted and placed in data/languages.yml, so that it can be replaced if required.

All of the code (everything except data/languages.yml) in this project is released under an MIT license.
