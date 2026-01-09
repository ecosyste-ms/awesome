require "test_helper"

class ListTest < ActiveSupport::TestCase
  context "find_spoken_language" do
    should "return nil when description is not present" do
      list = build(:list, description: nil)
      assert_nil list.find_spoken_language
    end

    should "return nil when description is empty" do
      list = build(:list, description: "")
      assert_nil list.find_spoken_language
    end

    should "return nil when description is too short" do
      list = build(:list, description: "Short text")
      assert_nil list.find_spoken_language
    end

    should "detect English language" do
      list = build(:list, description: "This is a collection of awesome resources for learning programming and software development")
      assert_equal "English", list.find_spoken_language
    end

    should "detect German language" do
      list = build(:list, description: "Dies ist eine Sammlung von großartigen Ressourcen zum Erlernen der Programmierung und Softwareentwicklung")
      assert_equal "German", list.find_spoken_language
    end

    should "detect Spanish language" do
      list = build(:list, description: "Esta es una colección de recursos increíbles para aprender programación y desarrollo de software")
      assert_equal "Spanish", list.find_spoken_language
    end

    should "handle descriptions with emojis" do
      list = build(:list, description: "This is a collection of awesome resources 🚀 for learning programming 💻 and software development")
      assert_equal "English", list.find_spoken_language
    end

    should "handle descriptions with markdown emojis" do
      list = build(:list, description: "This is a collection of awesome resources :rocket: for learning programming :computer: and software development")
      assert_equal "English", list.find_spoken_language
    end
  end
end
