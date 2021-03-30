//
//  ContentView.swift
//  PhotoExchanger
//
//  Created by Oleg Koptev on 30.03.2021.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State var pickerIsPresented = false
    @State var selectedImage: UIImage?
    private func sharePhoto() {
        guard let selectedImage = selectedImage else { return }
        let av = UIActivityViewController(activityItems: [ selectedImage ], applicationActivities: nil)
        av.excludedActivityTypes = [ .saveToCameraRoll ]
        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.tertiarySystemFill)
                    .edgesIgnoringSafeArea(.horizontal)
                
                Group {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        GeometryReader { geo in
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geo.size.width * 0.7)
                                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .toolbar {
                Button(action: { pickerIsPresented = true }) {
                    Image(systemName: "plus")
                }
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button(action: { sharePhoto() }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $pickerIsPresented) {
                PhotoPicker(isPresented: $pickerIsPresented) { image in
                    selectedImage = image
                }
            }
            .navigationTitle("Photo Exchanger")
        }
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onImport: (UIImage) -> Void
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: PHPickerViewControllerDelegate {
        private let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            print(results)
            
            guard let itemProvider = results.first?.itemProvider else {
                parent.isPresented = false
                return
            }
            
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        if let image = image as? UIImage {
                            self.parent.onImport(image)
                        } else {
                            self.parent.onImport(UIImage(systemName: "exclamationmark.circle")!)
                            print("Couldn't load image with error: \(error?.localizedDescription ?? "unknown error")")
                        }
                    }
                }
            }
            
            parent.isPresented = false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
