require 'minitest/autorun'
require 'language_list'

class LanguageListTest < Minitest::Test
  def test_all_languages
    assert_equal 7707, LanguageList::ALL_LANGUAGES.length
  end

  def test_common_languages
    assert_equal 71, LanguageList::COMMON_LANGUAGES.length
  end

  def test_living_languages
    assert_equal 6986, LanguageList::LIVING_LANGUAGES.length
  end

  def test_iso_iso_639_1_languages
    assert_equal 184, LanguageList::ISO_639_1.length
  end

  def test_find_by_iso_639_1
    english = LanguageList::LanguageInfo.find_by_iso_639_1('en')
    assert_equal 'en', english.iso_639_1
    assert_equal 'eng', english.iso_639_3
    assert_equal 'English', english.name
  end

  def test_find_by_iso_639_1_with_nil
    result = LanguageList::LanguageInfo.find_by_iso_639_1(nil)
    assert_equal nil, result
  end

  def test_find_by_iso_639_1_with_empty_string
    result = LanguageList::LanguageInfo.find_by_iso_639_1('')
    assert_equal nil, result
  end

  def test_find_by_iso_639_1_with_frozen_string
    english = LanguageList::LanguageInfo.find_by_iso_639_1('en'.freeze)
    assert_equal 'en', english.iso_639_1
    assert_equal 'eng', english.iso_639_3
    assert_equal 'English', english.name
  end

  def test_find_by_iso_639_3
    english = LanguageList::LanguageInfo.find_by_iso_639_3('eng')
    assert_equal 'en', english.iso_639_1
    assert_equal 'eng', english.iso_639_3
    assert_equal 'English', english.name
  end

  def test_find_by_iso_639_3_with_nil
    result = LanguageList::LanguageInfo.find_by_iso_639_3(nil)
    assert_equal nil, result
  end

  def test_find_by_iso_639_3_with_empty_string
    result = LanguageList::LanguageInfo.find_by_iso_639_3('')
    assert_equal nil, result
  end

  def test_find_by_iso_639_3_with_frozen_string
    english = LanguageList::LanguageInfo.find_by_iso_639_3('eng'.freeze)
    assert_equal 'en', english.iso_639_1
    assert_equal 'eng', english.iso_639_3
    assert_equal 'English', english.name
  end

  def test_find_by_name_with_nil
    result = LanguageList::LanguageInfo.find_by_name(nil)
    assert_equal nil, result
  end

  def test_find_by_name_with_empty_string
    result = LanguageList::LanguageInfo.find_by_name('')
    assert_equal nil, result
  end

  def test_find_by_name_with_frozen_string
    english = LanguageList::LanguageInfo.find_by_name('English'.freeze)
    assert_equal 'en', english.iso_639_1
    assert_equal 'eng', english.iso_639_3
    assert_equal 'eng', english.iso_639_2b
    assert_equal 'eng', english.iso_639_2t
    assert_equal 'English', english.name
  end

  def test_find_by_name
    english = LanguageList::LanguageInfo.find_by_name('English')
    assert_equal 'en', english.iso_639_1
    assert_equal 'eng', english.iso_639_3
    assert_equal 'eng', english.iso_639_2b
    assert_equal 'eng', english.iso_639_2t
    assert_equal 'English', english.name
  end

  def test_case_insensitive_find_by_name
    english = LanguageList::LanguageInfo.find_by_name('english')
    assert_equal 'en', english.iso_639_1
    assert_equal 'eng', english.iso_639_3
    assert_equal 'English', english.name
  end

  def test_find_with_nil
    result = LanguageList::LanguageInfo.find(nil)
    assert_equal nil, result
  end

  def test_find_with_empty_string
    result = LanguageList::LanguageInfo.find('')
    assert_equal nil, result
  end

  def test_find_with_frozen_string
    english = LanguageList::LanguageInfo.find('EN'.freeze)
    assert_equal 'en', english.iso_639_1
    assert_equal 'eng', english.iso_639_3
    assert_equal 'English', english.name
  end

  def test_find_with_iso_639_1_code
    english = LanguageList::LanguageInfo.find('en')
    assert_equal 'en', english.iso_639_1
    assert_equal 'eng', english.iso_639_3
    assert_equal 'English', english.name
  end

  def test_case_insensitive_find_with_iso_639_1_code
    english = LanguageList::LanguageInfo.find('EN')
    assert_equal 'en', english.iso_639_1
    assert_equal 'eng', english.iso_639_3
    assert_equal 'English', english.name
  end

  def test_find_with_iso_639_2b_code
    macedonian = LanguageList::LanguageInfo.find('mac')
    assert_equal 'mk', macedonian.iso_639_1
    assert_equal 'mac', macedonian.iso_639_2b
    assert_equal 'mkd', macedonian.iso_639_2t
    assert_equal 'mkd', macedonian.iso_639_3
    assert_equal 'Macedonian', macedonian.name
  end

  def test_case_insensitive_find_with_iso_639_2b_code
    macedonian = LanguageList::LanguageInfo.find('MAC')
    assert_equal 'mk', macedonian.iso_639_1
    assert_equal 'mac', macedonian.iso_639_2b
    assert_equal 'mkd', macedonian.iso_639_2t
    assert_equal 'mkd', macedonian.iso_639_3
    assert_equal 'Macedonian', macedonian.name
  end

  def test_find_with_iso_639_2t_code
    macedonian = LanguageList::LanguageInfo.find('mkd')
    assert_equal 'mk', macedonian.iso_639_1
    assert_equal 'mac', macedonian.iso_639_2b
    assert_equal 'mkd', macedonian.iso_639_2t
    assert_equal 'mkd', macedonian.iso_639_3
    assert_equal 'Macedonian', macedonian.name
  end

  def test_case_insensitive_find_with_iso_639_2t_code
    macedonian = LanguageList::LanguageInfo.find('MKD')
    assert_equal 'mk', macedonian.iso_639_1
    assert_equal 'mac', macedonian.iso_639_2b
    assert_equal 'mkd', macedonian.iso_639_2t
    assert_equal 'mkd', macedonian.iso_639_3
    assert_equal 'Macedonian', macedonian.name
  end

  def test_find_with_iso_639_3_code
    english = LanguageList::LanguageInfo.find('eng')
    assert_equal 'en', english.iso_639_1
    assert_equal 'eng', english.iso_639_3
    assert_equal 'English', english.name
  end

  def test_case_insensitive_find_with_iso_639_3_code
    english = LanguageList::LanguageInfo.find('Eng')
    assert_equal 'en', english.iso_639_1
    assert_equal 'eng', english.iso_639_3
    assert_equal 'English', english.name
  end

  def test_find_with_name
    english = LanguageList::LanguageInfo.find('English')
    assert_equal 'en', english.iso_639_1
    assert_equal 'eng', english.iso_639_3
    assert_equal 'eng', english.iso_639_2b
    assert_equal 'eng', english.iso_639_2t
    assert_equal 'English', english.name
  end

  def test_sort_should_order_by_name
    sorted = LanguageList::COMMON_LANGUAGES.sort
    expected = LanguageList::COMMON_LANGUAGES.map(&:name).sort

    assert_equal expected, sorted.map(&:name)
  end

  def test_common_name_when_present
    greek = LanguageList::LanguageInfo.find('el')
    assert_equal 'Greek', greek.common_name
  end

  def test_common_name_when_not_present
    english = LanguageList::LanguageInfo.find('en')
    assert_equal english.name, english.common_name
  end

  def test_cannot_change_constants
    assert_raises RuntimeError, TypeError do
      LanguageList::ALL_LANGUAGES[0] = nil
    end

    assert_raises RuntimeError, TypeError do
      LanguageList::ISO_639_1[0] = nil
    end

    assert_raises RuntimeError, TypeError do
      LanguageList::LIVING_LANGUAGES[0] = nil
    end

    assert_raises RuntimeError, TypeError do
      LanguageList::COMMON_LANGUAGES[0] = nil
    end

    assert_raises RuntimeError, TypeError do
      LanguageList::BY_NAME[0] = nil
    end

    assert_raises RuntimeError, TypeError do
      LanguageList::BY_ISO_639_1[0] = nil
    end

    assert_raises RuntimeError, TypeError do
      LanguageList::BY_ISO_639_3[0] = nil
    end

    assert_raises RuntimeError, TypeError do
      LanguageList::BY_ISO_639_2T[0] = nil
    end

    assert_raises RuntimeError, TypeError do
      LanguageList::BY_ISO_639_2B[0] = nil
    end
  end
end
