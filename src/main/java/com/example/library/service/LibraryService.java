package com.example.library.service;

import com.example.library.entity.Author;
import com.example.library.entity.Book;
import com.example.library.repository.AuthorRepository;
import com.example.library.repository.BookRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
public class LibraryService {

    private final BookRepository bookRepository;
    private final AuthorRepository authorRepository;

    public LibraryService(BookRepository bookRepository, AuthorRepository authorRepository) {
        this.bookRepository = bookRepository;
        this.authorRepository = authorRepository;
    }

    public List<String> findBookTitlesByAuthorNombre(String nombre) {
        return authorRepository.findBookTitlesByNombre(nombre);
    }

    @Transactional(readOnly = false)
    public Book saveBook(Book book, Author... authors) {
        for (Author author : authors) {
            if (!book.getAuthors().contains(author)) {
                book.addAuthor(author);
            }
            if (!author.getBooks().contains(book)) {
                author.addBook(book);
            }
        }
        // Save Book first to get an ID, then Authors so join table gets populated.
        book = bookRepository.save(book);
        for (Author author : authors) {
            authorRepository.save(author);
        }
        return book;
    }

    @Transactional(readOnly = true)
    public void flush() {
        bookRepository.flush();
        authorRepository.flush();
    }

    @Transactional(readOnly = true)
    public List<Book> findAllBooks() {
        return bookRepository.findAll();
    }
}
