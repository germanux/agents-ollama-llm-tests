import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';

import { Author, Book, ErrorResponse } from './models';

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

  getBooks(): Observable<Book[]> {
    return this.http.get<Book[]>(`${this.baseUrl}/books`);
  }

  createBook(title: string, description: string, authorIds: number[]): Observable<Book> {
    return this.http.post<Book>(`${this.baseUrl}/books`, { title, description, authorIds });
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
