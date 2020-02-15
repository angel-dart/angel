// GENERATED CODE - DO NOT MODIFY BY HAND
declare module 'angel_serialize_generator' {
  interface Book {
    id?: string;
    created_at?: any;
    updated_at?: any;
    author?: string;
    title?: string;
    description?: string;
    page_count?: number;
    not_models?: number[];
    camelCase?: string;
  }
  interface Author {
    id?: string;
    created_at?: any;
    updated_at?: any;
    name: string;
    age: number;
    books?: Book[];
    newest_book?: Book;
  }
  interface Library {
    id?: string;
    created_at?: any;
    updated_at?: any;
    collection?: LibraryCollection;
  }
  interface LibraryCollection {
    [key: string]: Book;
  }
  interface Bookmark {
    id?: string;
    created_at?: any;
    updated_at?: any;
    history?: number[];
    page: number;
    comment?: string;
  }
}