import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';

import { Author, Book, Publisher, ErrorResponse } from './models';

@Injectable({
  providedIn: 'root'
})
export class ApiService {
  private readonly baseUrl = '/api';

  constructor(private http: HttpClient) {}

  getAuthors(): Observable<Author[]> {
    return this.http.get<Author[]>(`${this.baseUrl}/authors`);
  }

  createAuthor(firstName: string, lastName: string, age: number | null): Observable<Author> {
    return this.http.post<Author>(`${this.baseUrl}/authors`, { firstName, lastName, age });
  }

  updateAuthor(id: number, firstName: string, lastName: string, age: number | null): Observable<Author> {
    return this.http.put<Author>(`${this.baseUrl}/authors/${id}`, { firstName, lastName, age });
  }

  deleteAuthor(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/authors/${id}`);
  }

  getBooks(): Observable<Book[]> {
    return this.http.get<Book[]>(`${this.baseUrl}/books`);
  }

  createBook(title: string, argument: string, genre: string, authorIds: number[], publisherId: number | null): Observable<Book> {
    return this.http.post<Book>(`${this.baseUrl}/books`, { title, argument, genre, authorIds, publisherId });
  }

  updateBook(id: number, title: string, argument: string, genre: string, authorIds: number[], publisherId: number | null): Observable<Book> {
    return this.http.put<Book>(`${this.baseUrl}/books/${id}`, { title, argument, genre, authorIds, publisherId });
  }

  deleteBook(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/books/${id}`);
  }

  uploadCover(id: number, file: File): Observable<Book> {
    const formData = new FormData();
    formData.append('file', file);
    return this.http.put<Book>(`${this.baseUrl}/books/${id}/cover`, formData);
  }

  deleteCover(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/books/${id}/cover`);
  }

  getBookCover(id: number): Observable<Blob> {
    return this.http.get(`${this.baseUrl}/books/${id}/cover`, { responseType: 'blob' });
  }

  getPublishers(): Observable<Publisher[]> {
    return this.http.get<Publisher[]>(`${this.baseUrl}/publishers`);
  }

  createPublisher(name: string, country: string): Observable<Publisher> {
    return this.http.post<Publisher>(`${this.baseUrl}/publishers`, { name, country });
  }

  updatePublisher(id: number, name: string, country: string): Observable<Publisher> {
    return this.http.put<Publisher>(`${this.baseUrl}/publishers/${id}`, { name, country });
  }

  deletePublisher(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/publishers/${id}`);
  }

  getAuthorBookTitles(authorId: number): Observable<string[]> {
    return this.http.get<string[]>(`${this.baseUrl}/authors/${authorId}/book-titles`);
  }

  private handleError(error: HttpErrorResponse): Observable<never> {
    let message = 'An error occurred';
    if (error.error && error.error.message) {
      message = error.error.message;
    } else if (error.status === 0) {
      message = 'Network error or server not available';
    }
    return throwError(() => new Error(message));
  }
}
