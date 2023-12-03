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
    show_word_progress
    create_player
  end

  def create_player
    player = Player.new(self)
  end

  def play(player)
    puts "For debugging, the word is: #{@selected_word}."
    show_hangman_state
    puts "Welcome to Hangman. You know how to play. Don't lose please. Start guessing."
    puts "You can type 'save' or 'load' at any time."
    player.make_guess while @wrong_guesses < 7 && is_game_won? == false && !@game_paused
  end

  def show_word_progress
    puts @word_so_far
  end

  def valid_guess?(guess)
    guess.length == 1 && !guessed_letters.include?(guess) && guess.match?(/^[A-Za-z]+$/) || guess == 'save' || guess == 'load'
  end

  def handle_correct_guess(guess)
    guessed_letters.push(guess)
    puts 'Correct.'
    update_word_status(guess)
    show_word_progress
  end

  def handle_incorrect_guess(guess)
    guessed_letters.push(guess)
    self.wrong_guesses += 1
    show_hangman_state
    puts "Wrong. Guesses remaining: #{7 - wrong_guesses}"
    show_word_progress
  end

  def show_hangman_state
    puts @@hangman_states[@wrong_guesses]
  end

  def update_word_status(guess)
    (0...@selected_word.length).each do |index|
      if @selected_word[index] == guess
        @word_so_far[index * 2] = guess # Using * 2 because I have spaces between underscores
      end
    end
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
    @game_paused = true
    puts 'Loading...'
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
    puts 'player created'
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
  end
end

hangman = Game.new
