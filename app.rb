class Game
  @@words = File.read('words.txt').split

  attr_accessor :selected_word, :guessed_letters, :word_so_far, :hangman_states, :wrong_guesses, :game_paused

  def initialize
    @selected_word = @@words.sample
    @guessed_letters = []
    @word_so_far = '_ ' * selected_word.length
    @hangman_states = [
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
    player.make_guess while @wrong_guesses < 7 && is_game_won? == false && !@game_paused
  end

  def show_word_progress
    puts @word_so_far
  end

  def valid_guess?(guess)
    guess.length == 1 && !guessed_letters.include?(guess) && guess.match?(/^[A-Za-z]+$/) || guess == 'save'
  end

  def show_hangman_state
    puts hangman_states[@wrong_guesses]
  end

  def update_word_status(guess)
    (0...@selected_word.length).each do |index|
      if @selected_word[index] == guess
        @word_so_far[index * 2] = guess # Using * 2 because I have spaces between underscores
      end
    end
  end

  def is_game_won?
    if @word_so_far.include?("_")
      false
    else
      puts 'You win!'
      true
    end
  end
end

class Player
  def initialize(hangman)
    @hangman = hangman
    puts 'player created'
    @hangman.play(self)
  end

  def make_guess
    guess = gets.chomp
    if guess.downcase == 'save'
      save_game
      return
    end

    if @hangman.valid_guess?(guess)
      if @hangman.selected_word.include?(guess)
        @hangman.guessed_letters.push(guess)
        puts 'Correct.'
        @hangman.update_word_status(guess)
      else
        @hangman.guessed_letters.push(guess)
        @hangman.wrong_guesses += 1
        @hangman.show_hangman_state
        puts "Wrong. Guesses remaining: #{7 - @hangman.wrong_guesses}"
      end
      @hangman.show_word_progress
    else
      puts "Invalid guess. Already guessed it or it's not a letter. Try again."
    end
  end

  def save_game
    @hangman.game_paused = true
    puts 'Saved!'
  end
end

hangman = Game.new
