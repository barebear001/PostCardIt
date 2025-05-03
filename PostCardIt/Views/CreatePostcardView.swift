//
//  MapPreviewView.swift
//  PostCardIt
//
//  Created by Taiyue Liu on 5/2/25.
//
import SwiftUI

// CreatePostcardView.swift
struct CreatePostcardView: View {
    @State private var selectedCountry = "United States"
    @State private var message = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isShowingPreview = false
    
    let countries = ["United States", "Canada", "Mexico", "Brazil", "France", "Japan", "Australia"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Destination")) {
                    Picker("Country", selection: $selectedCountry) {
                        ForEach(countries, id: \.self) {
                            Text($0)
                        }
                    }
                }
                
                Section(header: Text("Message")) {
                    TextEditor(text: $message)
                        .frame(height: 150)
                }
                
                Section(header: Text("Photo")) {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        HStack {
                            Text("Choose Photo")
                            Spacer()
                            if selectedImage != nil {
                                Image(uiImage: selectedImage!)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(5)
                            } else {
                                Image(systemName: "photo")
                            }
                        }
                    }
                }
                
                Section {
                    Button("Preview Postcard") {
                        isShowingPreview = true
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(message.isEmpty)
                }
            }
            .navigationTitle("Create Postcard")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $isShowingPreview) {
                PostcardPreviewDetailView(country: selectedCountry, message: message, image: selectedImage)
            }
        }
    }
}

struct CreatePostcardView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePostcardView()
    }
}
