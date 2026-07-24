package com.example.benchmark.backend.service;

import com.example.benchmark.backend.exception.ConflictException;
import com.example.benchmark.backend.exception.ResourceNotFoundException;
import com.example.benchmark.backend.model.Author;
import com.example.benchmark.backend.model.Book;
import com.example.benchmark.backend.model.Publisher;
import com.example.benchmark.backend.repository.AuthorRepository;
import com.example.benchmark.backend.repository.BookRepository;
import com.example.benchmark.backend.repository.PublisherRepository;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@Transactional
public class LibraryService {

    private final AuthorRepository authorRepository;
    private final BookRepository bookRepository;
    private final PublisherRepository publisherRepository;

    public LibraryService(AuthorRepository authorRepository, BookRepository bookRepository, PublisherRepository publisherRepository) {
        this.authorRepository = authorRepository;
        this.bookRepository = bookRepository;
        this.publisherRepository = publisherRepository;
    }

    public Author persistAuthor(String firstName, String lastName, Integer age) {
        Author author = new Author(firstName, lastName, age);
        return authorRepository.save(author);
    }

    @Transactional
    public Book persistBookWithAuthors(String title, String argument, String genre, Set<Long> authorIds, Long publisherId) {
        List<Author> authors = authorRepository.findAllById(authorIds);

        if (authors.size() != authorIds.size()) {
            throw new ResourceNotFoundException("Author", authorIds.stream().filter(id -> !authors.stream().map(Author::getId).toList().contains(id)).findFirst().orElse(0L));
        }

        Publisher publisher = null;
        if (publisherId != null) {
            publisher = publisherRepository.findById(publisherId)
                    .orElseThrow(() -> new ResourceNotFoundException("Publisher", publisherId));
        }

        Book book = new Book(title, argument);
        book.setGenre(genre);
        book.setPublisher(publisher);
        for (Author author : authors) {
            book.addAuthor(author);
        }

        return bookRepository.save(book);
    }

    public List<String> getBookTitlesByAuthorId(Long authorId) {
        return authorRepository.findBookTitlesByAuthorId(authorId);
    }

    public List<Author> findAllAuthors() {
        return authorRepository.findAll();
    }

    public List<Book> findAllBooks() {
        return bookRepository.findAll();
    }

    public List<Publisher> findAllPublishers() {
        return publisherRepository.findAll();
    }

    public Publisher persistPublisher(String name, String country) {
        Publisher publisher = new Publisher(name, country);
        return publisherRepository.save(publisher);
    }

    @Transactional
    public Author updateAuthor(Long id, String firstName, String lastName, Integer age) {
        Author author = authorRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Author", id));

        author.setFirstName(firstName);
        author.setLastName(lastName);
        author.setAge(age);

        return author;
    }

    @Transactional
    public Publisher updatePublisher(Long id, String name, String country) {
        Publisher publisher = publisherRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Publisher", id));

        publisher.setName(name);
        publisher.setCountry(country);

        return publisher;
    }

    @Transactional
    public Book updateBook(Long bookId, String title, String argument, String genre, Set<Long> authorIds, Long publisherId) {
        Book book = bookRepository.findById(bookId)
                .orElseThrow(() -> new ResourceNotFoundException("Book", bookId));

        book.setTitle(title);
        book.setArgument(argument);
        book.setGenre(genre);

        if (publisherId != null) {
            Publisher publisher = publisherRepository.findById(publisherId)
                    .orElseThrow(() -> new ResourceNotFoundException("Publisher", publisherId));
            book.setPublisher(publisher);
        } else {
            book.setPublisher(null);
        }

        Set<Author> currentAuthors = book.getAuthors();
        List<Author> newAuthors = authorRepository.findAllById(authorIds);

        if (newAuthors.size() != authorIds.size()) {
            throw new ResourceNotFoundException("Author", authorIds.stream().filter(aid -> !newAuthors.stream().map(Author::getId).toList().contains(aid)).findFirst().orElse(0L));
        }

        currentAuthors.clear();
        for (Author author : newAuthors) {
            book.addAuthor(author);
        }

        return book;
    }

    @Transactional
    public void deleteAuthor(Long id) {
        Author author = authorRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Author", id));

        List<Book> books = author.getBooks().stream().toList();
        for (Book book : books) {
            book.removeAuthor(author);
        }

        authorRepository.delete(author);
    }

    @Transactional
    public void deletePublisher(Long id) {
        Publisher publisher = publisherRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Publisher", id));

        if (publisherRepository.existsWithBooks(id)) {
            throw new ConflictException("Cannot delete Publisher that still has Books");
        }

        publisherRepository.delete(publisher);
    }

    @Transactional
    public void deleteBook(Long id) {
        Book book = bookRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Book", id));

        List<Author> authors = book.getAuthors().stream().toList();
        for (Author author : authors) {
            author.removeBook(book);
        }

        bookRepository.delete(book);
    }

    @Transactional
    public Book updateBookCover(Long id, String contentType, byte[] imageData) {
        Book book = bookRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Book", id));

        book.setCoverImageContentType(contentType);
        book.setCoverImageData(imageData);

        return book;
    }

    @Transactional
    public void deleteBookCover(Long id) {
        Book book = bookRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Book", id));

        book.setCoverImageData(null);
        book.setCoverImageContentType(null);
    }

    public Book getBookById(Long id) {
        return bookRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Book", id));
    }
}
