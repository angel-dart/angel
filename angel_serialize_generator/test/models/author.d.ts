// GENERATED CODE - DO NOT MODIFY BY HAND
declare module 'angel_serialize_generator' {
  interface Author {
    id?: string;
    name: string;
    age: number;
    books?: any[];
    newest_book?: any;
    created_at?: any;
    updated_at?: any;
  }
  interface Library {
    id?: string;
    collection: LibraryCollection;
    created_at?: any;
    updated_at?: any;
  }
  interface LibraryCollection {
    [key: string]: any;
  }
  interface Bookmark {
    id?: string;
    history: number[];
    page: number;
    comment: string;
    created_at?: any;
    updated_at?: any;
  }
}