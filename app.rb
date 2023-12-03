require 'yaml'

class Game
  @@words = File.read('words.txt').split
  @@hangman_states = [
    '
      +---+
      |   |
          |
          |
          |
          |
    =========
    ',
    '
      +---+
      |   |
      O   |
          |
          |
          |
    =========
    ',
    '
      +---+
      |   |
      O   |
      |   |
          |
          |
    =========
    ',
    '
      +---+
      |   |
      O   |
     /|   |
          |
          |
    =========
    ',
    %q(
      +---+
      |   |
      O   |
     /|\  |
          |
          |
    =========
    ),
    %q(
      +---+
      |   |
      O   |
     /|\  |
     /    |
          |
    =========
    ),
    %q(
      +---+
      |   |
      O   |
     /|\  |
     / \  |
          |
    =========
    )
  ]

  attr_accessor :selected_word, :guessed_letters, :word_so_far, :wrong_guesses, :game_paused

  def initialize
    @selected_word = @@words.sample
    @guessed_letters = []
    @word_so_far = '_ ' * selected_word.length
    @wrong_guesses = 0
    @game_paused = false
    player = Player.new(self)
  end

  def play(player)
    #puts "For debugging, the word is: #{@selected_word}."
    puts "Welcome to Hangman. You know how to play. Don't lose please. Start guessing."
    puts "You can type 'save' or 'load' at any time."
    show_hangman_state
    player.make_guess while @wrong_guesses < 7 && is_game_won? == false && !@game_paused
    puts "Game over. The word was \"#{selected_word}\"." if @wrong_guesses == 7
  end

  def valid_guess?(guess)
    guess.length == 1 && !guessed_letters.include?(guess) && guess.match?(/^[A-Za-z]+$/) || guess == 'save' || guess == 'load'
  end

  def handle_correct_guess(guess)
    guessed_letters.push(guess)
    update_word_status(guess)
    show_hangman_state
    puts 'Correct.'
  end

  def handle_incorrect_guess(guess)
    guessed_letters.push(guess)
    self.wrong_guesses += 1
    show_hangman_state
    puts "Wrong. #{show_remaining_guesses}"
  end

  def show_hangman_state
    puts @@hangman_states[@wrong_guesses]
    puts "#{@word_so_far}\n\n"
  end

  def update_word_status(guess)
    (0...@selected_word.length).each do |index|
      if @selected_word[index] == guess
        @word_so_far[index * 2] = guess # Using * 2 because I have spaces between underscores
      end
    end
  end

  def show_used_letters
    puts "You have guessed the following: #{@guessed_letters}."
  end

  def show_remaining_guesses
    puts "Guesses remaining: #{7 - @wrong_guesses}"
  end

  def is_game_won?
    if @word_so_far.include?('_')
      false
    else
      puts 'You win!'
      true
    end
  end

  def save_game
    folder_path = 'save_states'
    file_name = Time.now.strftime('%d.%m.%Y.%k.%M')
    full_path = File.join(folder_path, file_name)

    Dir.mkdir(folder_path) unless Dir.exist?(folder_path)

    File.open(full_path, 'w') do |file|
      file.puts "#{to_yaml}"
    end

    puts "File created at #{full_path}"
    @game_paused = true
  end

  def load_game
    save_files = Dir.entries('save_states/').reject { |entry| ['.', '..'].include?(entry) }
    sorted_save_files = save_files.sort

    if sorted_save_files.length == 0
      puts 'No save states exist yet.'
      puts 'Continue with your existing game by guessing a letter. :-)'
      return
    end

    puts 'Here are the available save states. Enter the corresponding number to load it.'
    puts "You can also enter 'b' to go back to your original game instead."

    sorted_save_files.each_with_index do |entry, index|
      puts "#{index + 1}: #{entry}"
    end

    choice = gets.chomp
    return if choice.downcase == 'b'

    selected_index = choice.to_i - 1
    if selected_index.between?(0, sorted_save_files.length - 1)
      load_state_from_file(File.join('save_states', sorted_save_files[selected_index]))
    else
      puts 'Invalid selection. Please try again.'
    end
  end


  def load_state_from_file(file_path)
    yaml_string = File.read(file_path)
    data = YAML.load(yaml_string)

    @selected_word = data[:selected_word]
    @guessed_letters = data[:guessed_letters]
    @word_so_far = data[:word_so_far]
    @wrong_guesses = data[:wrong_guesses]

    puts "Game loaded successfully."
    show_hangman_state
    show_used_letters
    show_remaining_guesses
  end

  def to_yaml
    YAML.dump({
      selected_word: @selected_word,
      guessed_letters: @guessed_letters,
      word_so_far: @word_so_far,
      wrong_guesses: @wrong_guesses,
      })
  end
end

class Player
  def initialize(hangman)
    @hangman = hangman
    @hangman.play(self)
  end

  def make_guess
    guess = gets.chomp.downcase
    return @hangman.save_game if guess == 'save'
    return @hangman.load_game if guess == 'load'

    unless @hangman.valid_guess?(guess)
      puts "Invalid guess. Already guessed it or it's not a letter. Try again."
      return
    end

    if @hangman.selected_word.include?(guess)
      @hangman.handle_correct_guess(guess)
    else
      @hangman.handle_incorrect_guess(guess)
    end
    @hangman.show_used_letters
  end
end

hangman = Game.new
