import { Component, inject } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';

import { ApiService } from './core/api.service';
import { Author, Book } from './core/models';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [FormsModule, ReactiveFormsModule],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent {
  private api = inject(ApiService);

  authors: Author[] = [];
  books: Book[] = [];

  // Form controls for author creation
  firstName = '';
  lastName = '';
  age: number | null = null;
  isCreatingAuthor = false;

  // Form controls for book creation
  bookTitle = '';
  bookDescription = '';
  selectedAuthorIds: number[] = [];
  isCreatingBook = false;

  // View state
  loadingAuthors = true;
  loadingBooks = true;
  error: string | null = null;

  ngOnInit() {
    this.loadAuthors();
    this.loadBooks();
  }

  loadAuthors() {
    this.loadingAuthors = true;
    this.error = null;
    this.api.getAuthors().subscribe({
      next: (authors) => {
        this.authors = authors;
        this.loadingAuthors = false;
      },
      error: (err) => {
        this.error = err.message;
        this.loadingAuthors = false;
      }
    });
  }

  loadBooks() {
    this.loadingBooks = true;
    this.api.getBooks().subscribe({
      next: (books) => {
        this.books = books;
        this.loadingBooks = false;
      },
      error: (err) => {
        this.error = err.message;
        this.loadingBooks = false;
      }
    });
  }

  createAuthor() {
    if (!this.firstName || !this.lastName) return;

    this.isCreatingAuthor = true;
    this.api.createAuthor(this.firstName, this.lastName, this.age).subscribe({
      next: (author) => {
        this.authors.push(author);
        this.firstName = '';
        this.lastName = '';
        this.age = null;
        this.isCreatingAuthor = false;
      },
      error: (err) => {
        this.error = err.message;
        this.isCreatingAuthor = false;
      }
    });
  }

  createBook() {
    if (!this.bookTitle || this.selectedAuthorIds.length === 0) return;

    this.isCreatingBook = true;
    this.api.createBook(this.bookTitle, this.bookDescription, this.selectedAuthorIds).subscribe({
      next: (book) => {
        this.books.push(book);
        this.bookTitle = '';
        this.bookDescription = '';
        this.selectedAuthorIds = [];
        this.isCreatingBook = false;
      },
      error: (err) => {
        this.error = err.message;
        this.isCreatingBook = false;
      }
    });
  }

  toggleAuthorSelection(authorId: number, event: Event) {
    const checkbox = event.target as HTMLInputElement;
    if (checkbox.checked) {
      if (!this.selectedAuthorIds.includes(authorId)) {
        this.selectedAuthorIds.push(authorId);
      }
    } else {
      this.selectedAuthorIds = this.selectedAuthorIds.filter(id => id !== authorId);
    }
  }

  getBookTitlesForAuthor(author: Author): string[] {
    const bookIds = this.books
      .filter(book => book.authorIds.includes(author.id))
      .map(book => book.title);
    return bookIds;
  }

  findAuthorById(id: number): Author | undefined {
    return this.authors.find(a => a.id === id);
  }

  getBookAuthors(authorIds: number[]): Author[] {
    return authorIds
      .map(id => this.findAuthorById(id))
      .filter((a): a is Author => !!a);
  }
}
