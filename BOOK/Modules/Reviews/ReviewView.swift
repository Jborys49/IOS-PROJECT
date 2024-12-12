import SwiftUI

struct ReviewView: View {
    @State var image: Image
    @State var description: String
    @State var tags: [String]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Display the image
                image
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)

                // Display the description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                        .padding(.bottom, 4)
                    HStack{
                        Text(description)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                }
                .padding(.horizontal)

                // Display the tags
                if !tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.headline)
                            .padding(.bottom, 4)

                        // Tags in a horizontal, flexible layout
                        WrapHStack(tags: tags) // Custom view to wrap tags
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle("Review Details")
    }
}

// Custom view for wrapping tags
struct WrapHStack: View {
    let tags: [String]

    var body: some View {
        GeometryReader { geometry in
            var width = CGFloat.zero
            var height = CGFloat.zero

            ZStack(alignment: .topLeading) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                        .foregroundColor(.black)
                        .alignmentGuide(.leading, computeValue: { dimension in
                            if abs(width - dimension.width) > geometry.size.width {
                                width = 0
                                height -= dimension.height
                            }
                            let result = width
                            if tag == tags.last {
                                width = 0 // Reset width after layout
                            } else {
                                width -= dimension.width
                            }
                            return result
                        })
                        .alignmentGuide(.top, computeValue: { _ in height })
                }
            }
            .frame(maxWidth: geometry.size.width, alignment: .leading)
        }
        .frame(height: 50) // Adjust height as needed for larger tag sets
    }
}
