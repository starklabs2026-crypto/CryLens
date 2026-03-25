import Foundation
import Supabase

let supabase: SupabaseClient = SupabaseClient(
    supabaseURL: URL(string: AppConfig.supabaseURL)!,
    supabaseKey: AppConfig.supabaseAnonKey
)
