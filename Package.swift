// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "CloudpaymentsSDK",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Cloudpayments",
            targets: ["Cloudpayments"]
        ),
        .library(
            name: "CloudpaymentsNetworking",
            targets: ["CloudpaymentsNetworking"]
        )
    ],
    targets: [
        .target(
            name: "Cloudpayments",
            dependencies: [
                "CloudpaymentsNetworking"
            ],
            path: "sdk",
            exclude: [
                "Pods",
                "sdk-Bridging-Header.h"
            ],
            resources: [
                .process("Resources")
            ]
        ),

        .target(
            name: "CloudpaymentsNetworking",
            path: "networking",
            sources: ["source"],
            resources: [
                .copy("Russian_Trusted_Root_CA.cer"),
                .copy("Russian_Trusted_Sub_CA_1.cer"),
                .copy("Russian_Trusted_Sub_CA_2.cer")
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
