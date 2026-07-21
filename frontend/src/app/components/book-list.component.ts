import { Component, DestroyRef, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { ApiService, Book } from '../api.service';

@Component({
  selector: 'app-book-list',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <div class="card">
      <h2>Books</h2>
      
      <div *ngIf="successMessage" class="alert alert-success">
        {{ successMessage }}
        <button (click)="closeSuccess()" type="button">&times;</button>
      </div>
      
      <div *ngIf="errorMessage" class="alert alert-error">
        {{ errorMessage }}
        <button (click)="clearError()" type="button">&times;</button>
      </div>
      
      <div class="book-controls">
        <a routerLink="/books/create">+ Add New Book</a>
      </div>
      
      <div *ngIf="loading" class="loading">Loading books...</div>
      
      <div *ngIf="!loading && books.length === 0" class="no-data">
        No books found.
      </div>
      
      <div *ngIf="!loading && books.length > 0" class="books-grid">
        <div 
          *ngFor="let book of books" 
          class="book-item"
        >
          <h3>{{ book.title }}</h3>
          <div *ngIf="book.authors && book.authors.length > 0" class="authors">
            Authors: {{ book.authors.join(', ') }}
          </div>
        </div>
      </div>
    </div>
  `
})
export class BookListComponent implements OnInit {
  private api = inject(ApiService);
  private destroyRef = inject(DestroyRef);

  books: Book[] = [];
  loading = false;
  successMessage: string | null = null;
  errorMessage: string | null = null;

  ngOnInit(): void {
    this.loadBooks();
  }

  loadBooks(): void {
    this.loading = true;
    this.errorMessage = null;
    
    this.api.getBooks().subscribe({
      next: (data) => {
        this.books = data;
        this.loading = false;
      },
      error: (error) => {
        this.errorMessage = error.message || 'Failed to load books';
        this.loading = false;
      }
    });
  }

  closeSuccess(): void {
    this.successMessage = null;
  }

  clearError(): void {
    this.errorMessage = null;
  }

  trackByBookId(index: number, book: Book): number | undefined {
    return book.id ?? index;
  }
}
