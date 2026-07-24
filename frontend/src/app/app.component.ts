import { Component, inject } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';

import { ApiService } from './core/api.service';
import { Author, Book, Publisher } from './core/models';

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
  publishers: Publisher[] = [];

  // Form controls for author creation
  firstName = '';
  lastName = '';
  age: number | null = null;
  isCreatingAuthor = false;

  // Form controls for book creation
  bookTitle = '';
  bookArgument = '';
  bookGenre = '';
  selectedAuthorIds: number[] = [];
  selectedPublisherId: number | null = null;
  isCreatingBook = false;

  // Publisher form controls
  publisherName = '';
  publisherCountry = '';
  isCreatingPublisher = false;

  // Edit state
  editingAuthor: Author | null = null;
  editingBook: Book | null = null;
  editingPublisher: Publisher | null = null;

  // View state
  loadingAuthors = true;
  loadingBooks = true;
  loadingPublishers = true;
  error: string | null = null;

  ngOnInit() {
    this.loadAuthors();
    this.loadBooks();
    this.loadPublishers();
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

  loadPublishers() {
    this.loadingPublishers = true;
    this.api.getPublishers().subscribe({
      next: (publishers) => {
        this.publishers = publishers;
        this.loadingPublishers = false;
      },
      error: (err) => {
        this.error = err.message;
        this.loadingPublishers = false;
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
    this.api.createBook(this.bookTitle, this.bookArgument, this.bookGenre, this.selectedAuthorIds, this.selectedPublisherId).subscribe({
      next: (book) => {
        this.books.push(book);
        this.bookTitle = '';
        this.bookArgument = '';
        this.bookGenre = '';
        this.selectedAuthorIds = [];
        this.selectedPublisherId = null;
        this.loadAuthors();
        this.isCreatingBook = false;
      },
      error: (err) => {
        this.error = err.message;
        this.isCreatingBook = false;
      }
    });
  }

  createPublisher() {
    if (!this.publisherName) return;

    this.isCreatingPublisher = true;
    this.api.createPublisher(this.publisherName, this.publisherCountry).subscribe({
      next: (publisher) => {
        this.publishers.push(publisher);
        this.publisherName = '';
        this.publisherCountry = '';
        this.isCreatingPublisher = false;
      },
      error: (err) => {
        this.error = err.message;
        this.isCreatingPublisher = false;
      }
    });
  }

  startEditAuthor(author: Author) {
    this.editingAuthor = { ...author };
  }

  saveAuthor() {
    if (!this.editingAuthor) return;

    const authorId = this.editingAuthor.id;
    this.api.updateAuthor(authorId, this.editingAuthor.firstName, this.editingAuthor.lastName, this.editingAuthor.age).subscribe({
      next: (updatedAuthor) => {
        const index = this.authors.findIndex(a => a.id === updatedAuthor.id);
        if (index !== -1) {
          this.authors[index] = updatedAuthor;
        }
        this.editingAuthor = null;
      },
      error: (err) => {
        this.error = err.message;
      }
    });
  }

  cancelEditAuthor() {
    this.editingAuthor = null;
  }

  deleteAuthor(id: number) {
    if (!confirm('Are you sure you want to delete this author?')) return;

    this.api.deleteAuthor(id).subscribe({
      next: () => {
        this.authors = this.authors.filter(a => a.id !== id);
        this.books = this.books.map(b => ({
          ...b,
          authorIds: b.authorIds.filter(aid => aid !== id)
        }));
      },
      error: (err) => {
        this.error = err.message;
      }
    });
  }

  startEditBook(book: Book) {
    this.editingBook = { ...book };
  }

  saveBook() {
    if (!this.editingBook) return;

    const bookId = this.editingBook.id;
    this.api.updateBook(bookId, this.editingBook.title, this.editingBook.argument, this.editingBook.genre, this.editingBook.authorIds, this.editingBook.publisherId).subscribe({
      next: (updatedBook) => {
        const index = this.books.findIndex(b => b.id === updatedBook.id);
        if (index !== -1) {
          this.books[index] = updatedBook;
        }
        this.editingBook = null;
      },
      error: (err) => {
        this.error = err.message;
      }
    });
  }

  cancelEditBook() {
    this.editingBook = null;
  }

  deleteBook(id: number) {
    if (!confirm('Are you sure you want to delete this book?')) return;

    this.api.deleteBook(id).subscribe({
      next: () => {
        this.books = this.books.filter(b => b.id !== id);
      },
      error: (err) => {
        this.error = err.message;
      }
    });
  }

  startEditPublisher(publisher: Publisher) {
    this.editingPublisher = { ...publisher };
  }

  savePublisher() {
    if (!this.editingPublisher) return;

    const publisherId = this.editingPublisher.id;
    this.api.updatePublisher(publisherId, this.editingPublisher.name, this.editingPublisher.country).subscribe({
      next: (updatedPublisher) => {
        const index = this.publishers.findIndex(p => p.id === updatedPublisher.id);
        if (index !== -1) {
          this.publishers[index] = updatedPublisher;
        }
        this.editingPublisher = null;
      },
      error: (err) => {
        this.error = err.message;
      }
    });
  }

  cancelEditPublisher() {
    this.editingPublisher = null;
  }

  deletePublisher(id: number) {
    const publisherHasBooks = this.books.some(b => b.publisherId === id);
    if (publisherHasBooks) {
      this.error = 'Cannot delete Publisher that still has Books';
      return;
    }

    if (!confirm('Are you sure you want to delete this publisher?')) return;

    this.api.deletePublisher(id).subscribe({
      next: () => {
        this.publishers = this.publishers.filter(p => p.id !== id);
        this.books = this.books.map(b => ({
          ...b,
          publisherId: b.publisherId === id ? null : b.publisherId
        }));
        if (this.selectedPublisherId === id) {
          this.selectedPublisherId = null;
        }
      },
      error: (err) => {
        this.error = err.message;
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

  findPublisherById(id: number | null): Publisher | undefined {
    if (!id) return undefined;
    return this.publishers.find(p => p.id === id);
  }
}
